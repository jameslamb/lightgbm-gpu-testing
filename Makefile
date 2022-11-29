.PHONY: lint
lint:
	shellcheck \
		--exclude=SC2002 \
		*.sh
