
ios_application(
    name = "BazelSample",
    binary = ":BazelSampleClasses",
    infoplist = "Info.plist",
)

objc_binary(
    name = "BazelSampleClasses",
    srcs = [
        "main.m",
        "AppDelegate.m",
        "ViewController.m",
    ],
    hdrs = glob(["*.h"]),
    asset_catalogs = ["Images.xcassets/AppIcon.appiconset/Contents.json"],
    storyboards = ["Base.lproj/Main.storyboard"],
)
