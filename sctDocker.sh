#!/bin/bash
#
#
   #===================================================================================
   #
   #         FILE: sctDocker.sh
   #
   #        USAGE: run it
   #
   #  DESCRIPTION: Run SCT utility in a docker container using WUI and VNC
   #      OPTIONS:  
   # REQUIREMENTS: 
   #       AUTHOR: Matt D
   #      CREATED: 01.17.2024
   #      VERSION: 1
   #
   #
   #
   #
   #
   #
   #===================================================================================

   # base command 
   # docker run -d --name ubuntu_desktop -v /dev/shm:/dev/shm -p 6080:80 -p 5900:5900 dorowu/ubuntu-desktop-lxde-vnc



function startUp()
{
    clear screen
    echo "##########################################################"
    echo "# This will manage your SCT Tool Docker container #"
    echo "##########################################################"

    echo
    echo
    echo 

    echo "################################################"
    echo "#                                              #"
    echo "#    What would you like to do ?               #"
    echo "#                                              #"
    echo "#          1 ==   Start docker image           #"
    echo "#                                              #"
    echo "#          2 ==   Stop docker image            #"
    echo "#                                              #"
    echo "#          3 ==   Bash access                  #"              
    echo "#                                              #"
    echo "#          4 ==   Get SCT                      #"
    echo "#                                              #"                                            
    echo "#          5 ==   WebUI                        #"
    echo "#                                              #"
    echo "#          6 ==   Do nothing                   #"
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
    msg="Please wait for container to start ...${1}..."
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

function copyFile()
{
    checkDocker
    export ubRunning=$(docker ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i ubuntu_desktop  | awk '{print $2}' )
    echo "Please enter the ABSOLUTE PATH to the file you want copied: "
    read thePath
    echo "Please enter the FILE NAME you want copied: "
    read theFile
    echo "Copying info: " $thePath/$theFile
    docker cp $thePath/$theFile $ubRunning:/tmp

}


function installUtils()
{
    checkDocker
    export ubRunning=$(docker ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i ubuntu_desktop  | awk '{print $2}' )
    docker exec -it -u 0 $ubRunning /usr/bin/apt update -y
    docker exec -it -u 0 $ubRunning /usr/bin/apt upgrade -y 
    docker exec -it -u 0 $ubRunning /usr/bin/apt-get install -y sudo wget rlwrap htop memstat cpustat zip curl file iputils-ping
    startUp
}

function getSCT()
{
    checkDocker
    export ubRunning=$(docker ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i ubuntu_desktop  | awk '{print $2}' )

    # download sct tool
    docker exec $ubRunning /usr/bin/curl -o /tmp/sct.zip --progress-bar -O -C - https://s3.amazonaws.com/publicsctdownload/Ubuntu/aws-schema-conversion-tool-1.0.latest.zip

    # unzip to /tmp
    docker exec $ubRunning /usr/bin/unzip /tmp/sct.zip -d /tmp

    # install local deb
    docker exec $ubRunning /usr/bin/dpkg -i /tmp/aws-schema-conversion-tool-1.0.675.deb

    # clean up and reclaim space
    # docker exec $ubRunning /usr/bin/rm -rdvf /tmp/dmsagent /tmp/agents /tmp/aws-schema* /tmp/sct.zip

}

function webUI()
{
    open http://localhost:6080
}

function createDocknet()
{
    docker network create docknet
}


function startUbuntu() # start or restart the container named ubuntu_desktop
{   
    checkDocker
    createDocknet
    # check to see if ubuntu_desktop is running and if running exit
    export ubRunning=$(docker ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i ubuntu_desktop  | awk '{print $2}' )
    export ubPresent=$(docker container ls -a --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i ubuntu_desktop  | awk '{print $2}')

    if [ "$ubRunning" == "ubuntu_desktop" ]; then
        echo "Ubuntu docker container is running, please select other option."
        sleep 5
        startUp
    elif [ "$ubPresent" == "ubuntu_desktop" ]; then
        echo "Ubuntu docker container found, restarting..."
        docker restart $ubPresent
        countDown
    else
        echo "No Ubuntu docker image found, provisioning..."
        #docker run -d --network="bridge" -p 6080:80 -p 5900:5900 -it --name ubuntu_desktop dorowu/ubuntu-desktop-lxde-vnc
        
        docker run -d --network="docknet" -p 6080:80 -p 5900:5900 -it --name ubuntu_desktop dorowu/ubuntu-desktop-lxde-vnc

        export runningUb=$(docker ps --no-trunc --format '{"name":"{{.Names}}"}'    | cut -d : -f 2 | sed 's/"//g' | sed 's/}//g')
        echo "Ubuntu is running as: "$runningUb
        echo "Please be patient as it takes time for the container to start..."
        countDown
        echo "Installing useful tools after provisioning container..."
        installUtils
    fi

}


function stopUbuntu()
{
    checkDocker
    export stopUb=$(docker ps --no-trunc | grep -i ubuntu_desktop | awk '{print $1}')
    echo $stopUb

    for i in $stopUb
    do
        echo $i
        echo "Stopping container: " $i
        docker stop $i
    done

    cleanVolumes

}

function removeContainer()
{
    docker rm $(docker ps -a | grep ubuntu_desktop | awk '{print $1}')
}


function cleanVolumes()
{
    docker volume prune -f 
}


function bashAccess()
{
    checkDocker
    export ubImage=$(docker ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i ubuntu_desktop  | awk '{print $2}' )
    docker exec -it $ubImage /bin/bash
}

function rootAccess()
{
    checkDocker
    export ubImage=$(docker ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i ubuntu_desktop  | awk '{print $2}' )
    docker exec -it -u 0 $ubImage /bin/bash
}



# process arguements to bypass the menu
if [ "$1" = "start" ]; then
    echo "Starting container..."
    startUbuntu
elif 
    [ "$1" = "stop" ]; then
        echo "Stopping container..."
        stopUbuntu
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
        startUbuntu
        ;;
    2) 
        stopUbuntu
        ;;
    3)
        bashAccess
        ;;   
    4)
        getSCT
        ;;
    5) 
        webUI 
        ;;
    6) 
        installUtils
        ;;
    7)
        copyFile
        ;;
    8)
        removeContainer
        ;;
    9)
        rootAccess
        ;;
    *) 
        badChoice
esac


