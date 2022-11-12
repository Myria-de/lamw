export JAVA_HOME=${/usr/libexec/java_home}
export PATH=${JAVA_HOME}/bin:$PATH
cd /home/te/fpcupdeluxe/projects/LAMWProjects/SmartFritz
jarsigner -verify -verbose -certs /home/te/fpcupdeluxe/projects/LAMWProjects/SmartFritz/bin/SmartFritz-release.apk
