export JAVA_HOME=${/usr/libexec/java_home}
export PATH=${JAVA_HOME}/bin:$PATH
cd /home/te/fpcupdeluxe/projects/LAMWProjects/SmartFritz
keytool -genkey -v -keystore smartfritz-release.keystore -alias smartfritz.keyalias -keyalg RSA -keysize 2048 -validity 10000 < /home/te/fpcupdeluxe/projects/LAMWProjects/SmartFritz/keytool_input.txt
