#!/bin/bash
# Copyright 2015, Google Inc.
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

set -e

cd $(dirname $0)

hash pod 2>/dev/null || { echo >&2 "Cocoapods needs to be installed."; exit 1; }
hash xcodebuild 2>/dev/null || {
    echo >&2 "XCode command-line tools need to be installed."
    exit 1
}

function test_build() {
    cd $1

    COCOAPODS_DISABLE_DETERMINISTIC_UUIDS=YES pod install

    # xcodebuild is very verbose. We filter its output and tell Bash to fail if any
    # element of the pipe fails.
    # TODO(jcanizales): Use xctool instead? Issue #2540.
    set -o pipefail
    XCODEBUILD_FILTER='(^===|^\*\*|\bfatal\b|\berror\b|\bwarning\b|\bfail)'
    xcodebuild \
        -workspace $1.xcworkspace \
        -scheme $1 \
        -destination name="iPhone 6" \
        build \
        | egrep "$XCODEBUILD_FILTER" \
        | egrep -v "(GPBDictionary|GPBArray)" -

    cd -
}

PIDS=()
CASES=()

for SUBDIR in */; do
    # Trim last "/"
    CASE=${SUBDIR%?}
    test_build $CASE &> $CASE/build.log &
    PIDS+=($!)
    CASES+=($CASE)
done

ERRORS=0
for INDEX in ${!PIDS[@]}; do
    PID="${PIDS[INDEX]}"
    CASE="${CASES[INDEX]}"
    if wait $PID; then
        echo $CASE builds successfully.
    else
        echo $CASE fails to build.
        ERRORS+=1
    fi
done
((ERRORS == 0))
