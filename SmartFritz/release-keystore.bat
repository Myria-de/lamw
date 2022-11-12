set JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
set PATH=%JAVA_HOME%/bin;%PATH%
set JAVA_TOOL_OPTIONS=-Duser.language=en
cd /home/te/fpcupdeluxe/projects/LAMWProjects/SmartFritz
keytool -genkey -v -keystore smartfritz-release.keystore -alias smartfritz.keyalias -keyalg RSA -keysize 2048 -validity 10000 < /home/te/fpcupdeluxe/projects/LAMWProjects/SmartFritz/keytool_input.txt
