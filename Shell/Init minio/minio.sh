#!/bin/sh
 
SERVICE_NAME=minio
 
usage()
{
        echo "-----------------------"
        echo "Usage: $0 start|restart)"
        echo "-----------------------"
}
 
if [ -z $1 ]; then
        usage
fi
 
service_start()
{
        echo "Starting service '${SERVICE_NAME}'..."
        OWD=`pwd`
        cd ${SERVICE_DIRECTORY} &amp;&amp; ./${SERVICE_STARTUP_SCRIPT}
        cd $OWD
        echo "Service '${SERVICE_NAME}' started successfully"
}
 
service_stop()
{
        echo "Stopping service '${SERVICE_NAME}'..."
        OWD=`pwd`
        cd ${SERVICE_DIRECTORY} &amp;&amp; ./${SERVICE_SHUTDOWN_SCRIPT}
        cd $OWD
        echo "Service '${SERVICE_NAME}' stopped"
}
 
case $1 in
        stop)
                service_stop
        ;;
        start)
                service_start
        ;;
        restart)
                service_stop
                service_start
        ;;
        *)
                usage
esac
exit 0
