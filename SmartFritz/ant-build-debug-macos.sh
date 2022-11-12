export PATH=/home/te/fpcupdeluxe/ccr/lamw-ant/apache-ant-1.10.8/bin:$PATH
export JAVA_HOME=${/usr/libexec/java_home}
export PATH=${JAVA_HOME}/bin:$PATH
cd /home/te/fpcupdeluxe/projects/LAMWProjects/SmartFritz/
ant -Dtouchtest.enabled=true debug
