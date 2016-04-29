Test latest version of BoringSSL
--------------------------------
- Go to boringssl's repo and copy the SHA of the last commit in master: https://boringssl.googlesource.com/boringssl/+/master
- Change BoringSSL.podspec in the gRPC repo (link!!) this way:
+ instead of :tag => '...', use:
+ :commit => 'SHA you just copied'
- Run gRPC ObjC tests
- In the rare case that err_data.c needs to be updated, either:
+ copy the contents of <grpc repo>/src/boringssl/err_data.c into the BoringSSL.podspec, or
+ regenerate err_data.c for your specific commit, following the instructions at the BoringSSL repo. You need to install Go.


Deploy new version of BoringSSL's pod.
--------------------------------------
So that the new release of gRPC uses the latest BoringSSL.

- Ask Adam Langley agl@google.com (CC: Matt Braithwaite mab@google.com) to please add a new tag for Cocoapods in the BoringSSL repo.
Example email:
```
Hi guys, we're ready for the next gRPC release.

I've tested it against BoringSSL commit 232127d (Fold EC_GROUP...), and would need a version_for_cocoapods_2.0 tag to be added.

Thanks a lot!
```
- Update the podspec's version number & commit
- pod trunk push BoringSSL.podspec --use-libraries --allow-warnings


Test gRPC.podspec
-----------------
- In your personal fork, create a branch and edit gRPC.podspec.template (link!!!!) to point to the new version number.
- ./tools/buildgen/generate_projects.sh
- commit and send to the release branch

"pod spec lint gRPC.podspec" will fail now, because the podspec points to a tag that doesn't exist in the repo.
We don't want to add the tag until after testing, though, so:

- Add a tag like this: git tag release-0_13_0-objectivec-0.13.0 and push it to your personal fork of the grpc repo on GitHub, pointing to the release branch
- Temporarily modify gRPC.podspec to point to your personal fork, instead of github.com/grpc/grpc
- pod spec lint gRPC.podspec --verbose --use-libraries
- If linting fails, this is a way to debug:
+ enter "script" in your terminal, so the output of pod spec lint will be captured in a file
+ repeat the lint command with --fail-fast --no-clean, so you can open the generated projects that had the failures
+ enter "exit" to exit the subshell

- After fixing any listing errors, run gRPC ObjC tests to make sure they pass (as local development might differ from what the linter checks).

Deploy gRPC.podspec
-------------------
- If any change was done to fix problems, commit and merge them into the release branch of the main repo.
- Recreate the version tag at the latest commit in the release branch.
- Push the version tag to the main grpc repo
- pod trunk push gRPC.podspec --use-libraries --allow-warnings
