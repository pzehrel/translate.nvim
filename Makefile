.PHONY: format format-check lint typecheck test check

format:
	stylua lua plugin scripts tests

format-check:
	stylua --check lua plugin scripts tests

lint:
	luacheck lua plugin scripts tests

typecheck:
	nvim --headless --clean -l scripts/typecheck.lua

test:
	nvim --headless --clean -u tests/minimal_init.lua -l tests/run.lua

check: format-check lint typecheck test
