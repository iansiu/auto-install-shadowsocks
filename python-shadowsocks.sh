#!/bin/bash

######	auto_install shadowsocks and autoban      ######
######  By:gebilaowang                            ######
######  Written:Thu 29 Jan 2015 08:52:21 PM CST   ######
######  Feedback: youweixiao@163.com              ######


######  统计时间    ######

function begin_time()
{
    begin_year_month_day=`date +%-Y年%-m月%-d日`
    begin_hours=`date +%-H`
    begin_minute=`date +%-M`
    begin_second=`date +%-S`
}

mail="123456@qq.com"     ## Inbox
rely=(epel-release python-setuptools m2crypto mailx)

function print_good () {
    echo -e "\x1B[01;32m[+]\x1B[0m $1"
}

function print_error () {
    echo -e "\x1B[01;31m[-]\x1B[0m $1"
}

funciton install_configure() {

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
	easy_install pip
	easy_install supervisor
	easy_install argparse
	pip install shadowsocks
	\cp autoban.py /etc/autoban.py 

echo "{
     \"server\":\"0.0.0.0\",
     \"server_port\":1500,
     \"local_port\":1080,
     \"password\":\"hello123\",
     \"timeout\":600,
     \"method\":\"rc4-md5\"
      }">/etc/shadowsocks.json

rm -rf /etc/supervisord.conf
echo_supervisord_conf >/etc/supervisord.conf

echo "[program:shadowsocks]
command=ssserver -c /etc/shadowsocks.json
autostart=true
autorestart=true
startsecs=3
redirect_stderr=true
stdout_logfile=/var/log/shadowsocks.log">>/etc/supervisord.conf


##### 优化TCP连接  #####

#rm -f /sbin/modprobe
#ln -s /bin/true /sbin/modprobe
#rm -f /sbin/sysctl
#ln -s /bin/true /sbin/sysctl
	#默认关闭，OpenVZ VPS用得上。

	> /etc/sysctl.conf

echo '
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.core.netdev_max_backlog = 250000
net.ipv4.tcp_mtu_probing=1
net.ipv4.tcp_congestion_control=hybla' >/etc/sysctl.conf

	sysctl -p

wget http://longshanren.net/auto_install_denyhosts.sh -O ~/auto_install_denyhosts.sh
sh ~/auto_install_denyhosts.sh

	echo "service supervisord start">>/etc/rc.local
	echo "python /etc/autoban.py < /var/log/shadowsocks.log">>/etc/rc.local
	echo "nohup tail -F /var/log/shadowsocks.log | python /etc/autoban.py 1>/dev/null 2>1 &">>/etc/rc.local

	sed -i "s/cmd = 'iptables -A INPUT -s %s -j DROP' % ip/cmd = 'iptables -A INPUT -s %s -j DROP \&\& service iptables save \>\/dev\/null' % ip/g" /etc/autoban.py

	if [ `which mail` >/dev/null ] ; then
	    echo "set from=doujingyx309@163.com" >>/etc/mail.rc               ## Your E-mail
	    echo "set smtp=smtp://smtp.163.com:25" >>/etc/mail.rc             ## E-mail server
	    echo "set smtp-auth-user=doujingyx309@163.com" >>/etc/mail.rc     ## Your E-mail
	    echo "set smtp-auth-password=t6317395" >>/etc/mail.rc             ## E-mail password
		sed -i "49 a\                cmd1 = 'echo \"Dear Xiao : \" >./tmp.log'" /etc/autoban.py
		sed -i "50 a\                cmd2 = 'echo \"\" \&\&  echo \"                Unknown ip is trying to brute force your shadowsocks\" >>./tmp.log'" /etc/autoban.py
		sed -i "51 a\                cmd3 = 'echo \"\" \&\&  echo \"                Deny IP      : \%s\" >>./tmp.log' \% ip" /etc/autoban.py
		sed -i "52 a\                cmd4 = 'echo \"\" \&\&  echo \"                Refusal Time : `date`\" >>./tmp.log'" /etc/autoban.py
		sed -i "53 a\                cmd5 = 'mail -s \"Please note that the warning from the vps\" $mail \<\./tmp.log'" /etc/autoban.py
		sed -i "56 a\                os.system\(cmd1\)" /etc/autoban.py
		sed -i "57 a\                os.system\(cmd2\)" /etc/autoban.py
		sed -i "58 a\                os.system\(cmd3\)" /etc/autoban.py
		sed -i "59 a\                os.system\(cmd4\)" /etc/autoban.py
		sed -i "60 a\                os.system\(cmd5\)" /etc/autoban.py
		echo "test mail service"|mail -s "E-mail Service OK" $mail
	fi
	echo ""
	print_good "shadowsocks successful installation"
	supervisord -c /etc/supervisord.conf
	
fi

}

function end_time()
{
    echo ""
    end_year_month_day=`date +%-Y年%-m月%-d日`
    end_hours=`date +%-H`
    end_minute=`date +%-M`
    end_second=`date +%-S`
 
    echo "从 $begin_year_month_day$begin_hours:$begin_minute:$begin_second 开始安装，到 $end_year_month_day$end_hours:$end_minute:$end_second 安装完成."
    echo ""
    echo 一共耗费了 $[$end_hours-begin_hours] 小时 $[$end_minute-begin_minute] 分钟 $[$end_second-$begin_second] 秒|sed 's/\-//'
    echo ""
}

begin_time;install_configure;end_time

rm -rf DenyHosts-2.6  DenyHosts-2.6.tar.gz  auto_install_denyhosts.sh dead.letter
rm -rf $0
