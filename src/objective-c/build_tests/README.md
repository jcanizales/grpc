These are empty XCode projects to test that gRPC can be installed via Cocoapods without compiler errors. The following variables have produced different behavior in the past, so their combinations need to be tested:

* Whether the app is in Swift or Objective-C.
* Whether the app uses frameworks or static libraries (`use_frameworks!` in the `Podfile`).
