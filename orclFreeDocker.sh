#!/bin/bash
#
#
   #===================================================================================
   #
   #         FILE: orclDocker.sh
   #
   #        USAGE: run it
   #
   #  DESCRIPTION:
   #      OPTIONS:  
   # REQUIREMENTS: 
   #       AUTHOR: Matt D
   #      CREATED: 11.10.2021
   #      UPDATED: 04.14.2024
   #      UPDATED: 05.02.2024
   #      VERSION: 1.5
   #
   #
   #
   #
   #
   #
   #===================================================================================

function startUp()
{
    clear screen
    echo "##########################################################"
    echo "# This will manage your Oracle Database Docker container #"
    echo "##########################################################"

    echo
    echo
    echo 

    echo "################################################"
    echo "#                                              #"
    echo "#    What would you like to do ?               #"
    echo "#                                              #"
    echo "#          1 ==   Start Oracle docker image    #"
    echo "#                                              #"
    echo "#          2 ==   Stop Oracle docker image     #"
    echo "#                                              #"
    echo "#          3 ==   Bash access                  #"
    echo "#                                              #"
    echo "#          4 ==   SQLPlus nolog connect        #"
    echo "#                                              #"
    echo "#          5 ==   SQLPlus SYSDBA               #"
    echo "#                                              #"
    echo "#          6 ==   SQLPlus user                 #"
    echo "#                                              #"
    echo "#          7 ==   Do NOTHING                   #"
    echo "#                                              #"
    echo "################################################"
    echo 
    echo "Please enter in your choice:> "
    read whatwhat

#   if [ $whatwhat -gt 9 ]
#       then
#       echo "Please enter a valid choice"
#       sleep 3
#       startUp
#   fi
    
}

function helpMe()
{
    echo "Help wanted..."
    sleep 5
    startUp
}

function doNothing()
{
    echo "################################################"
    echo "You don't want to do nothing...lazy..."
    echo "So...you want to quit...yes? "
    echo "Enter yes or no"
    echo "################################################"
    read doWhat
    if [[ $doWhat = yes ]]; then
        echo "Yes"
        echo "Bye! ¯\_(ツ)_/¯ " 
        exit 1
    else
        echo "No"
        startUp
    fi
    
}

function countDown()
{
    row=2
    col=2
    
    clear 
    msg="Please wait for Oracle to start ...${1}..."
    tput cup $row $col
    echo -n "$msg"
    l=${#msg}
    l=$(( l+$col ))
    for i in {10..1}
        do
            tput cup $row $l
            echo -n "$i"
            sleep 1
         done
    #startUp
}

function badChoice()
{
    echo "Invalid choice, please try again..."
    sleep 5
    startUp
}

function checkDocker()
{
    # open Docker, only if is not running...super hacky
    if (! docker stats --no-stream ); then
        open /Applications/Docker.app
    while (! docker stats --no-stream ); do
        echo "Waiting for Docker to launch..."
        sleep 1
    done
    fi
}

function copyIn()
{
    checkDocker
    export orclRunning=$(docker ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i Oracle_DB_Container  | awk '{print $2}' )
    echo "Please enter the ABSOLUTE PATH to the file you want copied: "
    read thePath
    echo "Please enter the FILE NAME you want copied: "
    read theFile
    echo "Copying info: " $thePath/$theFile
    docker cp $thePath/$theFile $orclRunning:/tmp

}

function copyOut()
{
    checkDocker
    export orclRunning=$(docker ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i Oracle_DB_Container  | awk '{print $2}' )
    echo "Please enter the ABSOLUTE PATH in the CONTAINER to the file you want copied to host: "
    read thePath
    echo "Please enter the FILE NAME in the CONTAINER you want copied: "
    read theFile
    echo "Copy info: " $orclRunning":" $thePath/$theFile
    docker cp $orclRunning:$thePath/$theFile /tmp/

}

function setorclPwd()
{
    checkDocker
    export orclRunning=$(docker ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i Oracle_DB_Container  | awk '{print $2}' )
    docker exec $orclRunning /home/oracle/setPassword.sh Oradoc_db1
}


function installUtils()
{
    checkDocker
    export orclRunning=$(docker ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i Oracle_DB_Container  | awk '{print $2}' )
    # workaround for ol repo issues, need to zero file
    #docker exec -it -u 0 $orclRunning echo > /etc/yum/vars/ociregion
    docker exec -it -u 0 $orclRunning /usr/bin/rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
    docker exec -it -u 0 $orclRunning /usr/bin/yum install -y sudo which java wget htop lsof zip unzip rlwrap
    docker exec $orclRunning wget -O /tmp/PS1.sh https://raw.githubusercontent.com/mattdee/orclDocker/main/PS1.sh
    docker exec $orclRunning bash /tmp/PS1.sh
    docker exec $orclRunning wget -O /opt/oracle/product/23ai/dbhomeFree/sqlplus/admin/glogin.sql https://raw.githubusercontent.com/mattdee/orclDocker/main/glogin.sql
    setorclPwd
    startUp
}

function setorclPwd()
{
    checkDocker
    export orclRunning=$(docker ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i Oracle_DB_Container  | awk '{print $2}' )
    docker exec $orclRunning /home/oracle/setPassword.sh Oradoc_db1
}

function createDocknet()
{
    docker network create -d bridge docknet
}

function listPorts()
{
    export orclRunning=$(docker ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i Oracle_DB_Container  | awk '{print $2}' )
    docker port $orclRunning
}

function startOracle() # start or restart the container named Oracle_DB_Container
{   
    checkDocker
    createDocknet
    # check to see if Oracle_DB_Container is running and if running exit
    export orclRunning=$(docker ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i Oracle_DB_Container  | awk '{print $2}' )
    export orclPresent=$(docker container ls -a --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i Oracle_DB_Container  | awk '{print $2}')

    if [ "$orclRunning" == "Oracle_DB_Container" ]; then
        echo "Oracle docker container is running, please select other option."
        sleep 5
        startUp
    elif [ "$orclPresent" == "Oracle_DB_Container" ]; then
        echo "Oracle docker container found, restarting..."
        docker restart $orclPresent
        countDown
    else
        echo "No Oracle docker image found, provisioning..."
        docker run -d --network="docknet" -p 1521:1521 -p 5902:5902 -p 5500:5500 -p 8080:8080 -p 8443:8443 -p 37017:27017 -it --name Oracle_DB_Container container-registry.oracle.com/database/free:23.4.0.0


        export runningOrcl=$(docker ps --no-trunc --format '{"name":"{{.Names}}"}'    | cut -d : -f 2 | sed 's/"//g' | sed 's/}//g')
        echo "Oracle is running as: "$runningOrcl
        echo "Please be patient as it takes time for the container to start..."
        countDown
        echo "Installing useful tools after provisioning container..."
        installUtils
    fi
    listPorts

}



function stopOracle()
{
    checkDocker
    export stopOrcl=$(docker ps --no-trunc | grep -i oracle | awk '{print $1}')
    echo $stopOrcl

    for i in $stopOrcl
    do
        echo $i
        echo "Stopping container: " $i
        docker stop $i
    done

    cleanVolumes

}


function cleanVolumes()
{
    docker volume prune -f 
}

function removeContainer()
{
    stopOracle
    docker rm $(docker ps -a | grep Oracle_DB_Container | awk '{print $1}')
}

function bashAccess()
{
    checkDocker
    export orclImage=$(docker ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i Oracle_DB_Container  | awk '{print $2}' )
    docker exec -it $orclImage /bin/bash
}

function rootAccess()
{
    checkDocker
    export orclImage=$(docker ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i Oracle_DB_Container  | awk '{print $2}' )
    docker exec -it -u 0 $orclImage /bin/bash
}



function sqlPlusnolog()
{
    checkDocker
    export orclImage=$(docker ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i Oracle_DB_Container  | awk '{print $2}' )
    docker exec -it $orclImage bash -c "source /home/oracle/.bashrc; sqlplus /nolog"
}

function sysDba()
{
    checkDocker
    export orclImage=$(docker ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i Oracle_DB_Container  | awk '{print $2}' )
    docker exec -it $orclImage bash -c "source /home/oracle/.bashrc; sqlplus sys/Oradoc_db1@'(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=127.0.0.1)(PORT=1521))
    (CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=FREEPDB1)))' as sysdba"
}

function createMatt()
{
    checkDocker
    export orclImage=$(docker ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i Oracle_DB_Container  | awk '{print $2}' )
    docker exec -it $orclImage bash -c "source /home/oracle/.bashrc; sqlplus sys/Oradoc_db1@'(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=127.0.0.1)(PORT=1521))
    (CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=FREEPDB1)))' as sysdba <<EOF
    grant sysdba,dba to matt identified by matt;
    exit;
EOF"
}


function sqlPlususer()
{
    checkDocker
    export orclImage=$(docker ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i Oracle_DB_Container  | awk '{print $2}' )
    createMatt
    docker exec -it $orclImage bash -c "source /home/oracle/.bashrc; sqlplus matt/matt@'(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=127.0.0.1)(PORT=1521))
    (CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=FREEPDB1)))'"
}

function setupORDS()
{
    # work in progress
    # need to configure ORDS for Mongo API access
    # https://docs.oracle.com/en/database/oracle/oracle-rest-data-services/23.4/ordig/oracle-api-mongodb-support.html#GUID-8C4D54C1-C2BF-4C94-A2E4-2183F25FD462
    checkDocker
    export orclImage=$(docker ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i Oracle_DB_Container  | awk '{print $2}' )
    docker exec -i -u 0 $orclImage curl -s "https://get.sdkman.io" | bash
    docker exec -it $orclImage /usr/bin/echo """source "/home/oracle/.sdkman/bin/sdkman-init.sh""">>/home/oracle/.bash_profile"
    docker exec -it -u 0 $orclImage /usr/bin/rpm -ivh https://yum.oracle.com/repo/OracleLinux/OL8/oracle/software/x86_64/getPackage/ords-23.4.0-8.el8.noarch.rpm
    # ORDS silent config
    docker exec -i -u 0 $orclImage echo ""Oradoc_db1 > /tmp/orclpwd""
    # silent set up
    # docker exec -i $orclImage /usr/local/bin/ords --config /etc/ords/config install --admin-user SYS --db-hostname localhost --db-port 1521 --db-servicename FREE --log-folder /tmp/ --feature-sdw true --feature-db-api true --feature-rest-enabled-sql true --password-stdin </tmp/orclpwd
    # manual set up
    docker exec -i $orclImage /usr/local/bin/ords --config /etc/ords/config install
    docker exec -it $orclImage /usr/local/bin/ords --config /etc/ords/config set mongo.enabled true
    docker exec -it $orclImage /usr/local/bin/ords config set mongo.enabled true
    
    docker exec -it $orclImage /usr/local/bin/ords serve


    # grant soda_app, create session, create table, create view, create sequence, create procedure, create job, unlimited tablespace to matt;    
    # connect matt/matt@localhost:1521/FREEPDB1
    # exec ords.enable_schema;



}

# process arguements to bypass the menu
if [ "$1" = "start" ]; then
    echo "Starting container..."
    startOracle
elif 
    [ "$1" = "stop" ]; then
        echo "Stopping container..."
        stopOracle
    elif
        [ "$1" = "restart" ]; then
            echo "Restarting container..."
            stopOracle
            startOracle
    elif
        [ "$1" = "bash" ]; then
            echo "Attempting bash acess..."
            bashAccess
    elif 
        [ "$1" = "sql" ]; then
        echo "Attempting SQLPlus access..."
        sqlPlususer
    elif
        [ "$1" = "help" ]; then
            echo "Providing help..."
            helpMe
    elif [ -z "$1" ]; then
        echo "No args...proceed with menu"
        #sleep 3
fi


# Let's go to work
startUp
case $whatwhat in
    1) 
        startOracle
        ;;
    2) 
        stopOracle
        ;;
    3)
        bashAccess
        ;;   
    4)
        sqlPlusnolog
        ;;
    5) 
        sysDba
        ;;
    6)
        sqlPlususer
        ;;
    7)
        doNothing
        ;;
    8)  # secret menu like in-n-out ;-) 
        cleanVolumes
        ;;
    9)
        rootAccess
        ;;
    10) 
        installUtils
        ;;
    11)
        copyIn
        ;;
    12)
        copyOut
        ;;
    13)
        removeContainer
        ;;
    14)
        setupORDS
        ;;
    *) 
        badChoice
esac


