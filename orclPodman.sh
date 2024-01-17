#!/bin/bash
#
#
   #===================================================================================
   #
   #         FILE: orclPodman.sh
   #
   #        USAGE: run it
   #
   #  DESCRIPTION:
   #      OPTIONS:  
   # REQUIREMENTS: 
   #       AUTHOR: Matt D
   #      CREATED: 11.10.2021
   #      UPDATED: 12.20.2023
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
    echo "# This will manage your Oracle Database Podman container #"
    echo "##########################################################"

    echo
    echo
    echo 

    echo "################################################"
    echo "#                                              #"
    echo "#    What would you like to do ?               #"
    echo "#                                              #"
    echo "#          1 ==   Start Oracle Podman image    #"
    echo "#                                              #"
    echo "#          2 ==   Stop Oracle Podman image     #"
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
    for i in {30..1}
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

function checkPodman()
{
    # open Podman, only if is not running...super hacky
    if (! podman stats --no-stream ); then
        open '/Applications/Podman Desktop.app'
    while (! podman stats --no-stream ); do
        echo "Waiting for Podman to launch..."
        sleep 1
    done
    fi
}

function copyFile()
{
    checkPodman
    export orclRunning=$(podman ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i Oracle_DB_Container  | awk '{print $2}' )
    echo "Please enter the ABSOLUTE PATH to the file you want copied: "
    read thePath
    echo "Please enter the FILE NAME you want copied: "
    read theFile
    echo "Copying info: " $thePath/$theFile
    docker cp $thePath/$theFile $orclRunning:/tmp

}

function setorclPwd()
{
    checkPodman
    export orclRunning=$(podman ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i Oracle_DB_Container  | awk '{print $2}' )
    podman exec $orclRunning /home/oracle/setPassword.sh Oradoc_db1
}


function installUtils()
{
    checkPodman
    export orclRunning=$(podman ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i Oracle_DB_Container  | awk '{print $2}' )
    podman exec -it -u 0 $orclRunning /usr/bin/rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
    podman exec -it -u 0 $orclRunning /usr/bin/yum install -y sudo which java wget rlwrap htop
    podman exec $orclRunning wget -O /tmp/PS1.sh https://raw.githubusercontent.com/mattdee/orclDocker/main/PS1.sh
    podman exec $orclRunning bash /tmp/PS1.sh
    podman exec $orclRunning wget -O /opt/oracle/product/23c/dbhomeFree/sqlplus/admin/glogin.sql https://raw.githubusercontent.com/mattdee/orclDocker/main/glogin.sql
    setorclPwd
    startUp
}

function setorclPwd()
{
    checkPodman
    export orclRunning=$(podman ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i Oracle_DB_Container  | awk '{print $2}' )
    podman exec $orclRunning /home/oracle/setPassword.sh Oradoc_db1
}


function startOracle() # start or restart the container named Oracle_DB_Container
{   
    checkPodman
    # check to see if Oracle_DB_Container is running and if running exit
    export orclRunning=$(podman ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i Oracle_DB_Container  | awk '{print $2}' )
    export orclPresent=$(podman container ls -a --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i Oracle_DB_Container  | awk '{print $2}')

    if [ "$orclRunning" == "Oracle_DB_Container" ]; then
        echo "Oracle podman container is running, please select other option."
        sleep 5
        startUp
    elif [ "$orclPresent" == "Oracle_DB_Container" ]; then
        echo "Oracle podman container found, restarting..."
        docker restart $orclPresent
        countDown
    else
        echo "No Oracle podman image found, provisioning..."
        podman run -d --network="bridge" -p 1521:1521 -p 5500:5500 -p 8080:8080 -it --name Oracle_DB_Container container-registry.oracle.com/database/free
        export runningOrcl=$(podman ps --no-trunc --format '{"name":"{{.Names}}"}'    | cut -d : -f 2 | sed 's/"//g' | sed 's/}//g')
        echo "Oracle is running as: "$runningOrcl
        echo "Please be patient as it takes time for the container to start..."
        countDown
        echo "Installing useful tools after provisioning container..."
        installUtils
    fi

}


function stopOracle()
{
    checkPodman
    export stopOrcl=$(podman ps --no-trunc | grep -i oracle | awk '{print $1}')
    echo $stopOrcl

    for i in $stopOrcl
    do
        echo $i
        echo "Stopping container: " $i
        podman stop $i
    done

    cleanVolumes

}


function cleanVolumes()
{
    podman volume prune -f 
}


function bashAccess()
{
    checkPodman
    export orclImage=$(podman ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i Oracle_DB_Container  | awk '{print $2}' )
    podman exec -it $orclImage /bin/bash
}

function rootAccess()
{
    checkPodman
    export orclImage=$(podman ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i Oracle_DB_Container  | awk '{print $2}' )
    podman exec -it -u 0 $orclImage /bin/bash
}



function sqlPlusnolog()
{
    checkPodman
    export orclImage=$(podman ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i Oracle_DB_Container  | awk '{print $2}' )
    podman exec -it $orclImage bash -c "source /home/oracle/.bashrc; rlwrap sqlplus /nolog"
}

function sysDba()
{
    checkPodman
    export orclImage=$(podman ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i Oracle_DB_Container  | awk '{print $2}' )
    podman exec -it $orclImage bash -c "source /home/oracle/.bashrc; rlwrap sqlplus sys/Oradoc_db1@'(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=127.0.0.1)(PORT=1521))
    (CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=FREEPDB1)))' as sysdba"
}

function createMatt()
{
    checkPodman
    export orclImage=$(podman ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i Oracle_DB_Container  | awk '{print $2}' )
    podman exec -it $orclImage bash -c "source /home/oracle/.bashrc; rlwrap sqlplus sys/Oradoc_db1@'(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=127.0.0.1)(PORT=1521))
    (CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=FREEPDB1)))' as sysdba <<EOF
    grant sysdba,dba to matt identified by matt;
    exit;
EOF"
}


function sqlPlususer()
{
    checkPodman
    export orclImage=$(podman ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i Oracle_DB_Container  | awk '{print $2}' )
    createMatt
    podman exec -it $orclImage bash -c "source /home/oracle/.bashrc; rlwrap sqlplus matt/matt@'(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=127.0.0.1)(PORT=1521))
    (CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=FREEPDB1)))'"
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
        copyFile
        ;;
    *) 
        badChoice
esac


