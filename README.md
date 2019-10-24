# Generika.cc

[![Build Status](
https://travis-ci.org/zdavatz/generikacc.svg?branch=master)](
https://travis-ci.org/zdavatz/generikacc)

## Features

* iPhone/iPad Support
* EAN-13 Barcord Scan
* Drug Preis Comparison Viewer
* Fachinformation/Patienteninformation Viewer
* Side effects Viewer
* Expiry date Saving


## Repository

https://github.com/zdavatz/generikacc


## Setup

### Requirements

* Xcode 9
* XCTest (for testing)
* Cocoapods

### Dependencies

See `Podfile`.

* AFNetworking
* JSONKit-NoWarning
* ZBarSDK
* NTMonthYearPicker

### Build

Install Cocoapods via `brew`.

```zsh
% cd /path/to/generikacc

# install cocoapods via homebrew
% brew install cocoapods
```

As next, setup dependencies via Cocoapods.

```zsh
# you need this only once at first (it takes for a while)
% pod setup
% pod install
```

Open `Generika.xcworkspace` (not `Generika.xcodeproj`) and build it.

### Debug

You may want to clean before rebuild, if you face something weird problem...

```zsh
# remove cache and compiled objects, log etc.
% rm -fr ~/Library/Developer/Xcode/DeriveredData
# reset pods
% rm -fr ./Pods
# this may change build configuration of `Pods` as default one
% pod install
```

And then click `Product` > `Clean` from menu (Shift + Command + K)


### Note

#### Build Active Architecture Only

It must be same values in Generika and Pods both.
For `Pods`, after install, `Debug` value will be turned to `YES` (as default).

```
# Generika
Debug Yes
Generika_AppStore No
Release No

# Pods
Debug Yes
Generika_AppStore No
Release No
```

#### Scheme

Check all schemas exists and its are valid from `Edit Scheme...` and
`Manage Schemes`.

```txt
# Edit Scheme... > Build
▶ Pods-Generika
  Generika
▶ GenerikaTests


# Manage Schemes
Generika
AFNetworking
JSONKit-NoWarning
NTMonthYearPicker
Pods-Generika
ZBarSDK
```

## Test

Run [XCTest](https://developer.apple.com/documentation/xctest?language=objc).

`test-runner` script supports multiple versions of _iphonesimulator_.

```zsh
# same as OS_VERSION="latest" ./bin/test-runner All, see `test-runner` script
% make test
% OS_VERSION="10.3.1" make test

# run single test case
% OS_VERSION="latest" ./bin/test-runner ProductTests/testInit
% OS_VERSION="10.3.1" ./bin/test-runner ProductTests/testInit
```

About target versions, see also _matrix_ in `.travis.yml`.


## Licence

`GPL-3.0`

```txt
Generika.cc
Copyright (c) 2012-2017 ywesee GmbH
```

See [LICENSE.txt](LICENCE).
