export JAVA_HOME=/home/te/android-studio/jre
cd /home/te/fpcupdeluxe/projects/LAMWProjects/HelloWorld
keytool -genkey -v -keystore helloworld-release.keystore -alias helloworld.keyalias -keyalg RSA -keysize 2048 -validity 10000 < /home/te/fpcupdeluxe/projects/LAMWProjects/HelloWorld/keytool_input.txt
