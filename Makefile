# -- testing

test:
	xcodebuild -workspace Generika.xcworkspace \
	  -scheme GenerikaTests \
	  -sdk iphonesimulator \
	  -destination 'platform=iOS Simulator,name=iPhone 6,OS=11.1' \
	  test
.PHONY: test

.DEFAULT_GOAL = test
default: test
