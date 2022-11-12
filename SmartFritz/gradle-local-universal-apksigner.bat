set Path=%PATH%;/home/te/Android/Sdk/platform-tools;/home/te/Android/Sdk/build-tools\29.0.3
set GRADLE_HOME=/home/te/fpcupdeluxe/ccr/lamw-gradle/gradle-6.2.1
set PATH=%PATH%;%GRADLE_HOME%\bin
zipalign -v -p 4 /home/te/fpcupdeluxe/projects/LAMWProjects/SmartFritz\build\outputs\apk\release\SmartFritz-universal-release-unsigned.apk /home/te/fpcupdeluxe/projects/LAMWProjects/SmartFritz\build\outputs\apk\release\SmartFritz-universal-release-unsigned-aligned.apk
apksigner sign --ks smartfritz-release.keystore --out /home/te/fpcupdeluxe/projects/LAMWProjects/SmartFritz\build\outputs\apk\release\SmartFritz-release.apk /home/te/fpcupdeluxe/projects/LAMWProjects/SmartFritz\build\outputs\apk\release\SmartFritz-universal-release-unsigned-aligned.apk
