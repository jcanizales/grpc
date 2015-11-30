These are empty XCode projects to test that gRPC can be installed via Cocoapods without compiler errors. The following variables have produced different behavior in the past, so their combinations need to be tested:

* Whether the app is in Swift or Objective-C.
* Whether the app uses frameworks or static libraries (`use_frameworks!` in the `Podfile`).

`build_test.sh` goes in parallel into each subdirectory, invokes `pod install` and builds the app using `xcodebuild`. It prints the success or failure of each build, and fails if any of them failed.
