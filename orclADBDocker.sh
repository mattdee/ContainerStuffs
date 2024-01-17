function startOracle() # start or restart the container named Oracle_ADB
{   
    #checkDocker
    # check to see if Oracle_ADB is running and if running exit
    export orclRunning=$(docker ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i Oracle_ADB  | awk '{print $2}' )
    export orclPresent=$(docker container ls -a --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i Oracle_ADB  | awk '{print $2}')

    if [ "$orclRunning" == "Oracle_ADB" ]; then
        echo "Oracle docker container is running, please select other option."
        sleep 5
        #startUp
    elif [ "$orclPresent" == "Oracle_ADB" ]; then
        echo "Oracle docker container found, restarting..."
        docker restart $orclPresent
        #countDown
    else
        echo "No Oracle docker image found, provisioning..."
        docker run --platform linux/amd64 -d --network="bridge" -p 1521:1521 -p 1522:1522 -p 8443:8443  -p 27017:27017 -p 5500:5500 -p 8080:8080 -e WORKLOAD_TYPE='ATP' -e WALLET_PASSWORD='ADB' -e ADMIN_PASSWORD='ADB' --cap-add SYS_ADMIN  -it --name Oracle_ADB container-registry.oracle.com/database/adb-free:latest
        export runningOrcl=$(docker ps --no-trunc --format '{"name":"{{.Names}}"}'    | cut -d : -f 2 | sed 's/"//g' | sed 's/}//g')
        echo "Oracle is running as: "$runningOrcl
        echo "Please be patient as it takes time for the container to start..."
        #countDown
        echo "Installing useful tools after provisioning container..."
        #installUtils
    fi

}



#docker run --platform linux/amd64 -d --network="bridge" -p 1521:1521 -p 1522:1522 -p 8443:8443  -p 27017:27017 -p 5500:5500 -p 8080:8080 -e WORKLOAD_TYPE='ATP' -e WALLET_PASSWORD='ADB' -e ADMIN_PASSWORD='ADB' --cap-add SYS_ADMIN  -it --name Oracle_ADB container-registry.oracle.com/database/adb-free:latest

startOracle