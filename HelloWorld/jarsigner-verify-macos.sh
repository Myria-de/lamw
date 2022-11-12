export JAVA_HOME=${/usr/libexec/java_home}
export PATH=${JAVA_HOME}/bin:$PATH
cd /home/te/fpcupdeluxe/projects/LAMWProjects/HelloWorld
jarsigner -verify -verbose -certs /home/te/fpcupdeluxe/projects/LAMWProjects/HelloWorld/bin/HelloWorld-release.apk
