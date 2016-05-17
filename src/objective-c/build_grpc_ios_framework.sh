#!/bin/bash
# Copyright 2016, Google Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#     * Neither the name of Google Inc. nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# This creates an iOS dynamic framework, grpc.framework, in the root of the repo, for the C-core
# gRPC library.

set -e

cd $(dirname $0)
cd ../.. # to the root of the repo

git submodule update --init

# TODO(jcanizales): Check dependencies are installed: Bazel, xcodeproj, xcpretty, and XCProj

SDK_VERSION=`xcrun --sdk iphoneos --show-sdk-version`

# Build the XCode project that will create the framework
# TODO(jcanizales): Does Buck support creating dynamic frameworks that can be used out-of-the-box?
TARGET_NAME=grpc_ios_framework
bazel build --ios_sdk_version=$SDK_VERSION :$TARGET_NAME --verbose_failures

# Get the symbols to export
# TODO(jcanizales): Open issue with Bazel to export them alright.
# TODO(jcanizales): Open issue with Bazel to declare lib${NAME}.a as an output of objc_library;
# otherwise this can't easily be made a genrule.
bazel build --ios_sdk_version=$SDK_VERSION :grpc_objc --verbose_failures
nm --extern-only --defined-only --no-sort --print-file-name bazel-bin/libgrpc_objc.a \
    | cut -d ' ' -f 4 \
    | sort > exported_symbols.txt

# Tell XCode to export them when creating the framework.
chmod u+w bazel-bin/$TARGET_NAME.xcodeproj/project.pbxproj 
xcproj --project bazel-bin/$TARGET_NAME.xcodeproj \
       --target $TARGET_NAME \
       write-build-setting EXPORTED_SYMBOLS_FILE `pwd`/exported_symbols.txt

# Add schemes so xcodebuild or xctool can build.
# The following uses the xcodeproj Ruby gem, which is unable to read a project created by Bazel
# unless xcproj has previously touched it (which fixes the project).
./src/objective-c/create_project_schemes.rb bazel-bin/$TARGET_NAME.xcodeproj

# Build the framework
# TODO(jcanizales): Use xcbuild?
rm -rf ./frameworks
set -o pipefail
xcodebuild -project bazel-bin/$TARGET_NAME.xcodeproj \
           -scheme $TARGET_NAME \
           -sdk iphonesimulator \
           -destination 'platform=iOS Simulator,OS=latest,name=iPhone 6s' \
           -derivedDataPath ./frameworks \
           build \
           | xcpretty

rm exported_symbols.txt

# Rename the framework
TARGET_DIR="Build/Products/Debug-iphonesimulator"

# Get the framework, rename it to "grpc," and clean up DerivedData directory
rm -rf grpc.framework

mv ./frameworks/$TARGET_DIR/$TARGET_NAME.framework .
mv $TARGET_NAME.framework grpc.framework
mv grpc.framework/$TARGET_NAME grpc.framework/grpc

rm -rf ./frameworks

# Change the install path of the dynamic library so apps can find it.
# TODO(jcanizales): Open issue on Bazel repo, as linkopts -install_name should be able to do this.
install_name_tool -id @rpath/grpc.framework/grpc grpc.framework/grpc

# Copy the public headers
cp -Rp include/grpc grpc.framework/Headers

# TODO(jcanizales): search for Sublime plugin to autocomplete paths
