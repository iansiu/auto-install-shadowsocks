
#!/bin/bash

######  auto_install_manyusersshadowsocks.sh      ######
######  By:gebilaowang                            ######
######  Written:Thu 29 Jan 2015 08:52:21 PM CST   ######
######  Feedback: xiaoxiong54@gmail.com           ######


######  统计时间    ######

begin_time() {
	
    begin_year_month_day=`date +%-Y年%-m月%-d日`
    begin_hours=`date +%-H`
    begin_minute=`date +%-M`
    begin_second=`date +%-S`
}


######    定义        #####      #### 安装很多依赖主要是考虑到minimal系统。

yumrely=(epel-release python-devel python-setuptools m2crypto libevent gcc gcc-c++)
piprely=(greenlet gevent gevent supervisor cymysql)
syst_version=`cat /etc/redhat-release |cut -d ' ' -f 1`
system=CentOS

function print_good () {
	echo -e "\x1B[01;32m[+]\x1B[0m $1"
}

function print_error () {
	echo -e "\x1B[01;31m[-]\x1B[0m $1"
}


#####  安装和配置     #####

function install_configure() {

if [ $UID != "0" ]; then
	print_error "Please use the root user"
	exit 1
fi


if [[ $system != $syst_version ]]; then
	print_error "Not centos system"
    exit 1
else
	for i in ${yumrely[*]}; do
		if ! rpm -q "$i">/dev/null ; then
			yum -y install $i
		fi
	done
    
    cd $PWD
	easy_install pip && easy_install argparse

	for p in ${piprely[*]}; do
		if ! pip show "$p">/dev/null ; then
			pip install $p
		fi
	done


##### 调整ulimit值 #####

	ulimit -n 51200

	sed -i '41a \* soft nofile 51200' /etc/security/limits.conf
	sed -i '42a \* hard nofile 51200' /etc/security/limits.conf



##### 优化TCP连接  #####

    #rm -f /sbin/modprobe
    #ln -s /bin/true /sbin/modprobe
    #rm -f /sbin/sysctl
    #ln -s /bin/true /sbin/sysctl
	#默认关闭，OpenVZ VPS用得上。

    echo 'net.ipv4.tcp_syncookies = 1
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
    net.ipv4.tcp_mtu_probing=1 ' >/etc/sysctl.conf
    #net.ipv4.tcp_congestion_control=hybla' >/etc/sysctl.conf ## 内核支持才可以

    sed -i 's/^    //g' /etc/sysctl.conf
    sysctl -p

##### 添加iptables规则 ##### 

	iptables -F

    echo ' 
    #!/bin/bash
	iptables -A FORWARD -m string --string "GET /scrape?info_hash=" --algo bm --to 65535 -j DROP
	iptables -A FORWARD -m string --string "GET /announce.php?info_hash=" --algo bm --to 65535 -j DROP
	iptables -A FORWARD -m string --string "GET /scrape.php?info_hash=" --algo bm --to 65535 -j DROP
	iptables -A FORWARD -m string --string "GET /scrape.php?passkey=" --algo bm --to 65535 -j DROP
	iptables -A FORWARD -m string --hex-string "|13426974546f7272656e742070726f746f636f6c|" --algo bm --to 65535 -j DROP
	iptables -A FORWARD -m string --string "www.360.com" --algo bm --to 65535 -j DROP
	iptables -A FORWARD -m string --string "www.360.cn" --algo bm --to 65535 -j DROP
	iptables -A OUTPUT -p tcp -m multiport --dport 24,25,50,57,105,106,109,110,143,158,209,218,220,465,587 -j REJECT --reject-with tcp-reset
	iptables -A OUTPUT -p tcp -m multiport --dport 993,995,1109,24554,60177,60179 -j REJECT --reject-with tcp-reset
	iptables -A OUTPUT -p udp -m multiport --dport 24,25,50,57,105,106,109,110,143,158,209,218,220,465,587 -j DROP
	iptables -A OUTPUT -p udp -m multiport --dport 993,995,1109,24554,60177,60179 -j DROP' >~/iptables.sh
	sh ~/iptables.sh

	service iptables save
	service iptables restart

##### 安装libsodium开启chacah20加密  #####

	https://download.libsodium.org/libsodium/releases/libsodium-1.0.8.tar.gz
	tar xf libsodium-1.0.8.tar.gz && cd libsodium-1.0.8
	./configure && make && make install
	echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
    ldconfig

##### 设置supervisor监控shadowsocks #####

	echo_supervisord_conf >/etc/supervisord.conf

	if [[ "$?" != 0 ]] ; then
		wget --no-check-certificate  https://pypi.python.org/packages/source/d/distribute/distribute-0.7.3.zip
		unzip distribute-0.7.3.zip
        cd distribute-0.7.3
        python setup.py install
		wget https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py -O - | python
        echo_supervisord_conf >/etc/supervisord.conf
	fi

    echo "" >>/etc/supervisord.conf
    echo '[program:shadowsocks]
    command=python /root/shadowsocks/server.py -c /root/shadowsocks/config.json
    autostart=true
    autorestart=true
    startsecs=3
    redirect_stderr=true
    stdout_logfile=/var/log/shadowsocks.log' >>/etc/supervisord.conf

	sed -i 's/^    //g' /etc/supervisord.conf

##### 安装Denyhosts防止SSH暴力破解    #####
    wget http://www.longshanren.net/soft/ssR.tar.gz
    tar xf ssR.tar.gz
	wget http://longshanren.net/auto_install_denyhosts.sh -O - | sh
	wget http://longshanren.net/soft/supervisord -O /etc/init.d/supervisord && chmod 755 /etc/init.d/supervisord || exit 1
	chkconfig --add supervisord
	chkconfig supervisord on
	echo "改下shadowsocks/Config.py里面的数据库信息就可以启动了"
	rm -rf DenyHosts-2.6  DenyHosts-2.6.tar.gz  auto_install_denyhosts.sh distribute-0.7.3.zip distribute-0.7.3 ~/iptables.sh
fi    
}

function end_time() {
    
    end_year_month_day=`date +%-Y年%-m月%-d日`
    end_hours=`date +%-H`
    end_minute=`date +%-M`
    end_second=`date +%-S`
    echo ""
    print_good "*******************************************************************************************************"
    print_good ""
    print_good "                Shadowsocks successful installation"
    print_good ""  
    print_good "                从 $begin_year_month_day $begin_hours:$begin_minute:$begin_second 开始，于 $end_year_month_day $end_hours:$end_minute:$end_second 完成."
    print_good ""
    print_good "                一共耗费了 $[$end_hours-begin_hours] 小时 $[$end_minute-begin_minute] 分钟 $[$end_second-$begin_second] 秒"|sed 's/\-//'
    print_good ""
    print_good "*******************************************************************************************************"
    echo ""
}
    
	begin_time&&install_configure&&end_time&&rm -rf $0
