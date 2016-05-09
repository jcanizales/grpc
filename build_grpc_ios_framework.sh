# TODO(jcanizales): Check dependencies are installed: Bazel and XCProj

# Build the XCode project that will create the framework
bazel build --ios_sdk_version=9.3 :ios_framework

# Get the symbols to export
nm --extern-only --defined-only --no-sort --print-file-name bazel-bin/libgrpc_objc.a | cut -d ' ' -f 4 | sort > exported_symbols.txt

# Tell XCode to export them when creating the framework
chmod u+w bazel-bin/ios_framework.xcodeproj/project.pbxproj 
xcproj --project bazel-bin/ios_framework.xcodeproj --target ios_framework write-build-setting EXPORTED_SYMBOLS_FILE `pwd`/exported_symbols.txt

# Build the framework
# TODO(jcanizales): Default to xcodebuild? Otherwise, check for xctool.
xctool -project bazel-bin/ios_framework.xcodeproj \
       -scheme ios_framework \
       -sdk iphonesimulator9.3 \
       -derivedDataPath /tmp/framework \
       build

# Copy the headers
cp -Rp include/grpc /tmp/framework/Build/Products/Debug-iphonesimulator/ios_framework.framework/Headers

# Rename the framework
mv /tmp/framework/Build/Products/Debug-iphonesimulator/ios_framework.framework /tmp/framework/Build/Products/Debug-iphonesimulator/grpc.framework
mv /tmp/framework/Build/Products/Debug-iphonesimulator/grpc.framework/ios_framework /tmp/framework/Build/Products/Debug-iphonesimulator/grpc.framework/grpc

# TODO search for sublime plugin to autocomplete paths
