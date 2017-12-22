# -- testing
ifeq (, $(OS_VERSION))
	OS_VERSION=latest
endif

test:
	OS_VERSION=$(OS_VERSION) ./bin/test-runner All
.PHONY: test

clean:
	xcrun simctl shutdown all
	xcrun simctl erase all
	xcodebuild clean -project Generika.xcodeproj -alltargets
	rm -fr $(HOME)/Library/Developer/Xcode/DerivedData/Generika-*
	rm -fr $(HOME)/Library/Developer/Xcode/DerivedData/ModuleCache


.DEFAULT_GOAL = test
default: test
