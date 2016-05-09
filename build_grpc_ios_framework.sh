#!/bin/bash

# TODO(jcanizales): Check dependencies are installed: Bazel and XCProj

set -e

# Build the XCode project that will create the framework
TARGET_NAME=grpc_ios_framework
bazel build --ios_sdk_version=9.3 :$TARGET_NAME

# Get the symbols to export
bazel build --ios_sdk_version=9.3 :grpc_objc
nm --extern-only --defined-only --no-sort --print-file-name bazel-bin/libgrpc_objc.a | cut -d ' ' -f 4 | sort > exported_symbols.txt

# Tell XCode to export them when creating the framework
chmod u+w bazel-bin/$TARGET_NAME.xcodeproj/project.pbxproj 
xcproj --project bazel-bin/$TARGET_NAME.xcodeproj --target $TARGET_NAME write-build-setting EXPORTED_SYMBOLS_FILE `pwd`/exported_symbols.txt

# Build the framework
# TODO(jcanizales): Default to xcodebuild? Otherwise, check for xctool.
xctool -project bazel-bin/$TARGET_NAME.xcodeproj \
       -scheme $TARGET_NAME \
       -sdk iphonesimulator9.3 \
       -derivedDataPath ./frameworks \
       build

# Rename the framework
TARGET_DIR="Build/Products/Debug-iphonesimulator"
# rm -rf ./frameworks/$TARGET_DIR/grpc.framework
# mv ./frameworks/$TARGET_DIR/ios_framework.framework      ./frameworks/$TARGET_DIR/grpc.framework
# mv ./frameworks/$TARGET_DIR/grpc.framework/ios_framework ./frameworks/$TARGET_DIR/grpc.framework/grpc

# Change the install path of the dynamic library so apps can find it.
# TODO(jcanizales): Open issue on Bazel repo, as linkopts -install_name should be able to do this.
# install_name_tool -id @executable_path/../Frameworks/grpc.framework/grpc ./frameworks/$TARGET_DIR/grpc.framework/grpc
install_name_tool -id /Users/jcanizales/git/grpc/src/objective-c/tests/Pods/frameworks/grpc.framework/grpc ./frameworks/$TARGET_DIR/grpc.framework/grpc

# Get the framework and clean up DerivedData directory
PODS_ROOT="src/objective-c/tests/Pods"
mkdir -p $PODS_ROOT/frameworks
rm -rf $PODS_ROOT/frameworks/grpc.framework
mv ./frameworks/$TARGET_DIR/grpc.framework $PODS_ROOT/frameworks
rm -rf ./frameworks/ModuleCache ./frameworks/Build ./frameworks/Info.plist ./frameworks/Logs

# Copy the headers
cp -Rp include/grpc $PODS_ROOT/frameworks/grpc.framework/Headers

# TODO search for sublime plugin to autocomplete paths
