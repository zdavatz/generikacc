# -- testing
ifeq (, $(OS_VERSION))
	OS_VERSION=latest
endif

test:
	OS_VERSION=$(OS_VERSION) ./bin/test-runner All
.PHONY: test

.DEFAULT_GOAL = test
default: test
