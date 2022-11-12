export PATH=/home/te/Android/Sdk/platform-tools:$PATH
export GRADLE_HOME=/home/te/fpcupdeluxe/ccr/lamw-gradle/gradle-6.2.1
export PATH=$PATH:$GRADLE_HOME/bin
source ~/.bashrc
gradle clean build --info
