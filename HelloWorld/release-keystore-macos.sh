export JAVA_HOME=${/usr/libexec/java_home}
export PATH=${JAVA_HOME}/bin:$PATH
cd /home/te/fpcupdeluxe/projects/LAMWProjects/HelloWorld
keytool -genkey -v -keystore helloworld-release.keystore -alias helloworld.keyalias -keyalg RSA -keysize 2048 -validity 10000 < /home/te/fpcupdeluxe/projects/LAMWProjects/HelloWorld/keytool_input.txt
