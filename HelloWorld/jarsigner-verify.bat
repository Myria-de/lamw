set JAVA_HOME=/home/te/android-studio/jre
path %JAVA_HOME%/bin;%path%
cd /home/te/fpcupdeluxe/projects/LAMWProjects/HelloWorld
jarsigner -verify -verbose -certs /home/te/fpcupdeluxe/projects/LAMWProjects/HelloWorld/bin/HelloWorld-release.apk
