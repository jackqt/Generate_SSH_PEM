#!/bin/sh 

ROOT_USER="root"
ROOT_HOME=$(eval echo ~${ROOT_NAME})
TMP_WEB_HOME=$ROOT_HOME/tmp/pyserver

USER_NAME="ecs-user"
USER_HOME=$(getent passwd ${USER_NAME}|cut -d: -f6)
USER_SSH_HOME="$USER_HOME/.ssh"
SSH_PRIVATE_KEY="id_rsa"
SSH_AUTHRIZED_KEY="authorized_keys"

ETC_SUDOER_USER_FILE=/etc/sudoers.d/users

function startwebserver {
    # Start web server for download the ssh private key
    if [ -d $TMP_WEB_HOME ]
    then
        rm -rf $TMP_WEB_HOME
    fi
    mkdir -p $TMP_WEB_HOME
    cd $TMP_WEB_HOME

    cp $USER_SSH_HOME/$SSH_PRIVATE_KEY $USER_NAME.pem

    IP_LIST=`ifconfig | awk -F "[: ]+" '/inet / { print $3 }'`
    echo -e "Copy & Paste the below URL into browser to download the private key\n"
    for ip in $IP_LIST
    do
        echo -e "\thttp://$ip:8000/$USER_NAME.pem\n"
    done

    echo "Press Ctrl-c to terminate the web server"
    python -m SimpleHTTPServer 8000 1>&2
}

function gensshkey {
    su -c "ssh-keygen -b 2048 -t rsa -f $USER_SSH_HOME/$SSH_PRIVATE_KEY -q -N \"\"" -s /bin/sh $USER_NAME
    su -c "cp $USER_SSH_HOME/id_rsa.pub $USER_SSH_HOME/$SSH_AUTHRIZED_KEY" -s /bin/sh $USER_NAME
}

function adduser {
    # Create specify user and add into group: adm
    id $USER_NAME 1>/dev/null 2>/dev/null
    if [ $? == 0 ]
    then
        if [ ! -d $USER_HOME ]
        then
            mkdir -p $USER_HOME
            chown -R $USER_NAME $USER_HOME
        fi
        usermod -G `id -g adm` $USER_NAME
    else
        useradd -G `id -g adm` $USER_NAME
    fi

    USER_HOME=$(getent passwd ${USER_NAME}|cut -d: -f6)
    USER_SSH_HOME="$USER_HOME/.ssh"
}
function createsshkey {
    # Generate ssh private/public key for the created user
    if [ -f $USER_SSH_HOME/id_rsa ]
    then
        echo -e "[31m [05m [Warning] There already is generated ssh key [0m" 
        echo -e "[31m [05m [Warning] If enter Y to download directory, or N to regenerate [0m" 
        read -p "(Download) [Y/N]:" answer
        if [ $answer == "Y" ]
        then 
            startwebserver
            exit
        elif [ $answer == "N" ]
        then
            cd $USER_HOME
            rm -f .ssh/id_rsa*
            gensshkey
        else
            exit
        fi
    else
        mkdir -p $USER_SSH_HOME
        chown -R $USER_NAME:$USER_NAME $USER_SSH_HOME
        gensshkey
    fi
}
function addtosudoer {
    # Add user into sudoers file
    grep $USER_NAME $ETC_SUDOER_USER_FILE 1>&2
    if [ $? != 0 ]
    then
        cat >> $ETC_SUDOER_USER_FILE << EOF
# User rules for $USER_NAME
$USER_NAME ALL=(ALL)NOPASSWD:ALL
EOF
    fi 

    chmod 400 $ETC_SUDOER_USER_FILE
}

function showhelp {
    echo "Usage: args [-h] [-u username]"
    echo "-h means help"
    echo "-u means specify username"
}

function main {
    adduser
    createsshkey
    addtosudoer
    startwebserver
}

while getopts "u:h" arg
do  
    case $arg in
        h)
            showhelp
            exit ;;
        u)
            USER_NAME="$OPTARG"
            main;;
        ?)
            showhelp ;;
    esac
done

