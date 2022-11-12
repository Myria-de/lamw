set Path=%PATH%;/home/te/Android/Sdk/platform-tools;/home/te/Android/Sdk/build-tools\29.0.3
set GRADLE_HOME=/home/te/fpcupdeluxe/ccr/lamw-gradle/gradle-6.2.1
set PATH=%PATH%;%GRADLE_HOME%\bin
zipalign -v -p 4 /home/te/fpcupdeluxe/projects/LAMWProjects/HelloWorld\build\outputs\apk\release\HelloWorld-release-unsigned.apk /home/te/fpcupdeluxe/projects/LAMWProjects/HelloWorld\build\outputs\apk\release\HelloWorld-release-unsigned-aligned.apk
apksigner sign --ks helloworld-release.keystore --out /home/te/fpcupdeluxe/projects/LAMWProjects/HelloWorld\build\outputs\apk\release\HelloWorld-release.apk /home/te/fpcupdeluxe/projects/LAMWProjects/HelloWorld\build\outputs\apk\release\HelloWorld-release-unsigned-aligned.apk
