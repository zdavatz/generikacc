# Generika.cc

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
* Ruby 2.3 (for [Cocoapods](https://cocoapods.org/) installed via Bundler)

### Dependencies

See `Podfile`.

* AFNetworking
* JSONKit-NoWarning
* ZBarSDK
* NTMonthYearPicker

### Build

```zsh
# use ruby which is installed macOS default
% which ruby
/usr/bin/ruby

% ruby --version
ruby 2.3.3p222 (2016-11-21 revision 56859) [universal.x86_64-darwin17]
```

Install Bundler via `gem`, and Cocoapods via `bundler`.

```zsh
% cd /path/to/generikacc

# install cocoapods via bundler
% gem install bundler
% bundle install --path .bundle/gems
# check installation of cocoapods
% bundle exec which pod
/path/to/pod
```

As next, setup dependencies via Cocoapods.

```zsh
# you need this only once at first (it takes for a while)
% bundle exec pod setup
% bundle exec pod install
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
% bundle exec pod install
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

Run [XCTest](https://developer.apple.com/documentation/xctest?language=objc)

```zsh
% make test
```


## Licence

`LGPL-2.1`

```txt
Generika.cc
Copyright (c) 2012-2017 ywesee GmbH
```

See [LICENSE.txt](LICENCE).
