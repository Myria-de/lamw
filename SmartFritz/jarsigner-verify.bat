set JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
path %JAVA_HOME%/bin;%path%
cd /home/te/fpcupdeluxe/projects/LAMWProjects/SmartFritz
jarsigner -verify -verbose -certs /home/te/fpcupdeluxe/projects/LAMWProjects/SmartFritz/bin/SmartFritz-release.apk
