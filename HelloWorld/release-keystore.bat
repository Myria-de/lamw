set JAVA_HOME=/home/te/android-studio/jre
set PATH=%JAVA_HOME%/bin;%PATH%
set JAVA_TOOL_OPTIONS=-Duser.language=en
cd /home/te/fpcupdeluxe/projects/LAMWProjects/HelloWorld
keytool -genkey -v -keystore helloworld-release.keystore -alias helloworld.keyalias -keyalg RSA -keysize 2048 -validity 10000 < /home/te/fpcupdeluxe/projects/LAMWProjects/HelloWorld/keytool_input.txt
