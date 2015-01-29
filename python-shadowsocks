#!/bin/bash

######	auto_install shadowsocks and autoban      ######
######  By:gebilaowang                            ######
######  Written:Thu 29 Jan 2015 08:52:21 PM CST   ######
######  Feedback: youweixiao@163.com              ######

mail="123456@qq.com"     ## Inbox
rely=(epel-release python-setuptools m2crypto supervisor mailx)

function print_good () {
    echo -e "\x1B[01;32m[+]\x1B[0m $1"
}

function print_error () {
    echo -e "\x1B[01;31m[-]\x1B[0m $1"
}

if [ $UID != "0" ]; then
	print_error "Please use the root user"
	exit 1			
else

    if [ ! -f ./autoban.py ]; then
		wget https://raw.githubusercontent.com/shadowsocks/shadowsocks/master/utils/autoban.py
    fi
    
    for i in ${rely[*]}; do
    	if ! rpm -q "$i">/dev/null ; then
        	yum -y install $i
		fi
	done
	#yum -y update
	#easy_install pip
	#easy_install argparse
	pip install shadowsocks
	\cp autoban.py ~/autoban.py 

echo "{
     \"server\":\"0.0.0.0\",
     \"server_port\":8388,
     \"local_port\":1080,
     \"password\":\"yourpassword\",
     \"timeout\":600,
     \"method\":\"aes-256-cfb\"
      }">/etc/shadowsocks.json

echo "[program:shadowsocks]
command=ssserver -c /etc/shadowsocks.json
autostart=true
autorestart=true
user=root
startsecs=3
log_stdout=true
log_stderr=true
logfile=/var/log/shadowsocks.log">>/etc/supervisord.conf

	echo "service supervisord start">>/etc/rc.local
	echo "python ~/autoban.py < /var/log/shadowsocks.log">>/etc/rc.local
	echo "nohup tail -F /var/log/shadowsocks.log | python ~/autoban.py 1>/dev/null 2>1 &">>/etc/rc.local

	sed -i "s/cmd = 'iptables -A INPUT -s %s -j DROP' % ip/cmd = 'iptables -A INPUT -s %s -j DROP \&\& service iptables save \>\/dev\/null' % ip/g" ~/autoban.py

	if [ `which mail` >/dev/null ] ; then
	    echo "set from=doujingyx309@163.com" >>/etc/mail.rc               ## Your E-mail
	    echo "set smtp=smtp://smtp.163.com:25" >>/etc/mail.rc             ## E-mail server
	    echo "set smtp-auth-user=doujingyx309@163.com" >>/etc/mail.rc     ## Your E-mail
	    echo "set smtp-auth-password=t6317395" >>/etc/mail.rc             ## E-mail password
		sed -i "49 a\                cmd1 = 'echo \"Dear Xiao : \" >./tmp.log'" ~/autoban.py
		sed -i "50 a\                cmd2 = 'echo \"\" \&\&  echo \"                Unknown ip is trying to brute force your shadowsocks\" >>./tmp.log'" ~/autoban.py
		sed -i "51 a\                cmd3 = 'echo \"\" \&\&  echo \"                Deny IP      : \%s\" >>./tmp.log' \% ip" ~/autoban.py
		sed -i "52 a\                cmd4 = 'echo \"\" \&\&  echo \"                Refusal Time : `date`\" >>./tmp.log'" ~/autoban.py
		sed -i "53 a\                cmd5 = 'mail -s \"Please note that the warning from the vps\" $mail \<\./tmp.log'" ~/autoban.py
		sed -i "56 a\                os.system\(cmd1\)" ~/autoban.py
		sed -i "57 a\                os.system\(cmd2\)" ~/autoban.py
		sed -i "58 a\                os.system\(cmd3\)" ~/autoban.py
		sed -i "59 a\                os.system\(cmd4\)" ~/autoban.py
		sed -i "60 a\                os.system\(cmd5\)" ~/autoban.py
		echo "test mail service"|mail -s "E-mail Service OK" $mail
	fi
	echo ""
	print_good "Been configured to automatically restart after 60 seconds"
	for s in `seq 60 -1 1`; do
        print_good "$s" && sleep 1
    done

    reboot
fi

