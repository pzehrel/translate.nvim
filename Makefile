.PHONY: format format-check lint test check

format:
	stylua lua plugin tests

format-check:
	stylua --check lua plugin tests

lint:
	luacheck lua plugin tests

test:
	nvim --headless --clean -u tests/minimal_init.lua -l tests/run.lua

check: format-check lint test

