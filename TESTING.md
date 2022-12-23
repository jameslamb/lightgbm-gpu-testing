# testing

Build the LightGBM GPU wheel.

```shell
cd /usr/local/src/LightGBM

sudo git config --global --add safe.directory /usr/local/src/LightGBM

sudo git remote add integrated-opencl \
    https://github.com/jgiannuzzi/LightGBM.git

sudo git fetch integrated-opencl linux-gpu-wheel
sudo git checkout linux-gpu-wheel

docker run --rm -ti \
    -v $PWD/artifacts:/artifacts \
    -e AZURE=true \
    -e BUILD_DIRECTORY=/vsts/lightgbm \
    -e BUILD_SOURCESDIRECTORY=/vsts/lightgbm \
    -e BUILD_ARTIFACTSTAGINGDIRECTORY=/artifacts \
    -e COMPILER=gcc \
    -e CONDA_ENV=test-env \
    -e LGB_VER=3.3.3.99 \
    -e OS_NAME=linux \
    -e PRODUCES_ARTIFACTS=true \
    -e PYTHON_VERSION=3.10 \
    -e SETUP_CONDA=false \
    -e TASK=swig \
    -e OMP_NUM_THREADS=4 \
    -e POCL_MAX_PTHREAD_COUNT=4 \
    --workdir=/vsts/lightgbm \
    lightgbm/vsts-agent:manylinux_2_28_x86_64-dev \
    bash


export PATH=/opt/miniforge/bin:"${PATH}"

git clone \
    --recursive \
    https://github.com/jgiannuzzi/LightGBM.git \
    --branch linux-gpu-wheel \
    .

git remote add upstream https://github.com/microsoft/LightGBM.git
git fetch upstream master

.ci/setup.sh

conda create -q -y -n $CONDA_ENV "python=$PYTHON_VERSION[build=*cpython]"
source activate $CONDA_ENV

cd $BUILD_DIRECTORY

# re-including python=version[build=*cpython] to ensure that conda doesn't fall back to pypy
conda install -q -y -n $CONDA_ENV \
    cloudpickle \
    dask-core \
    distributed \
    joblib \
    matplotlib \
    numpy \
    pandas \
    psutil \
    pytest \
    "python=$PYTHON_VERSION[build=*cpython]" \
    python-graphviz \
    scikit-learn \
    scipy || exit -1

ARCH=$(uname -m)
if [[ $ARCH == "x86_64" ]]; then
    PLATFORM="manylinux_2_28_x86_64"
else
    PLATFORM="manylinux2014_$ARCH"
fi

cd $BUILD_DIRECTORY/python-package
python setup.py bdist_wheel --integrated-opencl --plat-name=$PLATFORM --python-tag py3

# Make sure we can do both CPU and GPU; see tests/python_package_test/test_dual.py
export LIGHTGBM_TEST_DUAL_CPU_GPU=1
pip install --user $BUILD_DIRECTORY/python-package/dist/*.whl
LD_DEBUG=libs \
pytest -v $BUILD_DIRECTORY/tests/python_package_test/test_dual.py

mkdir $BUILD_DIRECTORY/build && cd $BUILD_DIRECTORY/build

if [[ $TASK == "gpu" ]]; then
    sed -i'.bak' 's/std::string device_type = "cpu";/std::string device_type = "gpu";/' $BUILD_DIRECTORY/include/LightGBM/config.h
    grep -q 'std::string device_type = "gpu"' $BUILD_DIRECTORY/include/LightGBM/config.h || exit -1  # make sure that changes were really done
    if [[ $METHOD == "pip" ]]; then
        cd $BUILD_DIRECTORY/python-package && python setup.py sdist || exit -1
        pip install --user $BUILD_DIRECTORY/python-package/dist/lightgbm-$LGB_VER.tar.gz -v --install-option=--gpu || exit -1
        pytest $BUILD_DIRECTORY/tests/python_package_test || exit -1
        exit 0
    elif [[ $METHOD == "wheel" ]]; then
        cd $BUILD_DIRECTORY/python-package && python setup.py bdist_wheel --gpu || exit -1
        pip install --user $BUILD_DIRECTORY/python-package/dist/lightgbm-$LGB_VER*.whl -v || exit -1
        pytest $BUILD_DIRECTORY/tests || exit -1
        exit 0
    elif [[ $METHOD == "source" ]]; then
        cmake -DUSE_GPU=ON ..
    fi
elif [[ $TASK == "cuda" || $TASK == "cuda_exp" ]]; then
    if [[ $TASK == "cuda" ]]; then
        sed -i'.bak' 's/std::string device_type = "cpu";/std::string device_type = "cuda";/' $BUILD_DIRECTORY/include/LightGBM/config.h
        grep -q 'std::string device_type = "cuda"' $BUILD_DIRECTORY/include/LightGBM/config.h || exit -1  # make sure that changes were really done
    else
        sed -i'.bak' 's/std::string device_type = "cpu";/std::string device_type = "cuda_exp";/' $BUILD_DIRECTORY/include/LightGBM/config.h
        grep -q 'std::string device_type = "cuda_exp"' $BUILD_DIRECTORY/include/LightGBM/config.h || exit -1  # make sure that changes were really done
        # by default ``gpu_use_dp=false`` for efficiency. change to ``true`` here for exact results in ci tests
        sed -i'.bak' 's/gpu_use_dp = false;/gpu_use_dp = true;/' $BUILD_DIRECTORY/include/LightGBM/config.h
        grep -q 'gpu_use_dp = true' $BUILD_DIRECTORY/include/LightGBM/config.h || exit -1  # make sure that changes were really done
    fi
    if [[ $METHOD == "pip" ]]; then
        cd $BUILD_DIRECTORY/python-package && python setup.py sdist || exit -1
        if [[ $TASK == "cuda" ]]; then
            pip install --user $BUILD_DIRECTORY/python-package/dist/lightgbm-$LGB_VER.tar.gz -v --install-option=--cuda || exit -1
        else
            pip install --user $BUILD_DIRECTORY/python-package/dist/lightgbm-$LGB_VER.tar.gz -v --install-option=--cuda-exp || exit -1
        fi
        pytest $BUILD_DIRECTORY/tests/python_package_test || exit -1
        exit 0
    elif [[ $METHOD == "wheel" ]]; then
        if [[ $TASK == "cuda" ]]; then
            cd $BUILD_DIRECTORY/python-package && python setup.py bdist_wheel --cuda || exit -1
        else
            cd $BUILD_DIRECTORY/python-package && python setup.py bdist_wheel --cuda-exp || exit -1
        fi
        pip install --user $BUILD_DIRECTORY/python-package/dist/lightgbm-$LGB_VER*.whl -v || exit -1
        pytest $BUILD_DIRECTORY/tests || exit -1
        exit 0
    elif [[ $METHOD == "source" ]]; then
        if [[ $TASK == "cuda" ]]; then
            cmake -DUSE_CUDA=ON ..
        else
            cmake -DUSE_CUDA_EXP=ON ..
        fi
    fi
elif [[ $TASK == "mpi" ]]; then
    if [[ $METHOD == "pip" ]]; then
        cd $BUILD_DIRECTORY/python-package && python setup.py sdist || exit -1
        pip install --user $BUILD_DIRECTORY/python-package/dist/lightgbm-$LGB_VER.tar.gz -v --install-option=--mpi || exit -1
        pytest $BUILD_DIRECTORY/tests/python_package_test || exit -1
        exit 0
    elif [[ $METHOD == "wheel" ]]; then
        cd $BUILD_DIRECTORY/python-package && python setup.py bdist_wheel --mpi || exit -1
        pip install --user $BUILD_DIRECTORY/python-package/dist/lightgbm-$LGB_VER*.whl -v || exit -1
        pytest $BUILD_DIRECTORY/tests || exit -1
        exit 0
    elif [[ $METHOD == "source" ]]; then
        cmake -DUSE_MPI=ON -DUSE_DEBUG=ON ..
    fi
else
    cmake ..
fi

make _lightgbm -j4 || exit -1

cd $BUILD_DIRECTORY/python-package && python setup.py install --precompile --user || exit -1
pytest $BUILD_DIRECTORY/tests || exit -1

if [[ $TASK == "regular" ]]; then
    if [[ $PRODUCES_ARTIFACTS == "true" ]]; then
        if [[ $OS_NAME == "macos" ]]; then
            cp $BUILD_DIRECTORY/lib_lightgbm.so $BUILD_ARTIFACTSTAGINGDIRECTORY/lib_lightgbm.dylib
        else
            if [[ $COMPILER == "gcc" ]]; then
                objdump -T $BUILD_DIRECTORY/lib_lightgbm.so > $BUILD_DIRECTORY/objdump.log || exit -1
                python $BUILD_DIRECTORY/helpers/check_dynamic_dependencies.py $BUILD_DIRECTORY/objdump.log || exit -1
            fi
            cp $BUILD_DIRECTORY/lib_lightgbm.so $BUILD_ARTIFACTSTAGINGDIRECTORY/lib_lightgbm.so
        fi
    fi
    cd $BUILD_DIRECTORY/examples/python-guide
    sed -i'.bak' '/import lightgbm as lgb/a\
import matplotlib\
matplotlib.use\(\"Agg\"\)\
' plot_example.py  # prevent interactive window mode
    sed -i'.bak' 's/graph.render(view=True)/graph.render(view=False)/' plot_example.py
    # requirements for examples
    conda install -q -y -n $CONDA_ENV \
        h5py \
        ipywidgets \
        notebook
    for f in *.py **/*.py; do python $f || exit -1; done  # run all examples
    cd $BUILD_DIRECTORY/examples/python-guide/notebooks
    sed -i'.bak' 's/INTERACTIVE = False/assert False, \\"Interactive mode disabled\\"/' interactive_plot_example.ipynb
    jupyter nbconvert --ExecutePreprocessor.timeout=180 --to notebook --execute --inplace *.ipynb || exit -1  # run all notebooks
fi


&& .ci/test.sh && chown -R $(id -u):$(id -g) /artifacts"
```
