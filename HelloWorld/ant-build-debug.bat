set Path=%PATH%;/home/te/fpcupdeluxe/ccr/lamw-ant/apache-ant-1.10.7/bin
set JAVA_HOME=/home/te/android-studio/jre
cd /home/te/fpcupdeluxe/projects/LAMWProjects/HelloWorld
call ant clean -Dtouchtest.enabled=true debug
if errorlevel 1 pause
