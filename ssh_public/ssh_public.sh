#!/bin/bash
: '
    NOTE:This script is used to establish the ssh public access,from one source server to multi target servers between any two uses.
    author:  alex.lvxin
    date:    2017-08-29
'
:'The file that contains all the target ips or hosts,one ip or host in one line of the file,as follow:
192.168.1.1
192.168.1.2
...
...
...
'
IP_FILE=$1
:'The client user name 
'
CLIENT_USER_NAME=root
#The client user's home directory
CLIENT_USER_DIR=/root
#The target user name used to login the target servers
TARGET_USER_NAME=hadp
#The target user's passwd used to access the target servers 
TARGET_USER_PASSWD=hadp


genExp ()
{
cat >scppub.exp<<EOF
#!/usr/bin/expect
spawn ssh-copy-id -i $CLIENT_USER_DIR/.ssh/id_rsa.pub $TARGET_USER_NAME@$SSH_IP
expect { 
"*yes/no*" {send "yes\r"; exp_continue}
"*password*" {send "$TARGET_USER_PASSWD\r";}
}
expect eof
EOF
chmod 755 scppub.exp
./scppub.exp > /dev/null
/bin/rm -rf scppub.exp
}


if [ -f $IP_FILE ]
then
	:
else
	echo
	echo "-------------Please touch $IP_FILE with the content as follows---------------"
	echo "111.111.111.111"
	echo "222.222.222.222"
	exit 0
fi

if ( rpm -qa | grep -q expect )
then
	:
else
	yum -y install expect > /dev/null
fi

if [ -f $CLIENT_USER_DIR/.ssh/id_rsa.pub ]
then
	echo "$CLIENT_USER_DIR/.ssh/id_rsa.pub is exist already! Do nothing"
else
	ssh-keygen
fi

for SSH_IP in `cat $IP_FILE`
do
	genExp
	if [ $? -eq 0 ]
	then
		echo "----------$SSH_IP is OK-----"
	else
		echo "----------$SSH_IP is failed------"
	fi
done
