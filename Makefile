# -- testing

test:
	./bin/test-runner All
.PHONY: test

.DEFAULT_GOAL = test
default: test
