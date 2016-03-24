#!/bin/bash

######	auto_install shadowsocks and denyhosts    ######
######  By:gebilaowang                            ######
######  Written:Thu 29 Jan 2015 08:52:21 PM CST   ######
######  Feedback: youweixiao@163.com              ######


######  统计时间    ######

function begin_time() {
    begin_year_month_day=`date +%-Y年%-m月%-d日`
    begin_hours=`date +%-H`
    begin_minute=`date +%-M`
    begin_second=`date +%-S`
}

#####   定义       #####

rely=(epel-release python-setuptools m2crypto libevent unzip wget gcc gcc-c++ python-devel)
piprely=(greenlet gevent gevent supervisor shadowsocks)
serverip=`ifconfig | grep -v 127.0.0.1|sed -n '/inet addr/s/^[^:]*:\([0-9.]\{7,15\}\) .*/\1/p'`
port='8358'
passwd='hello123'
method='rc4-md5'
system="CentOS"
syst_version=`cat /etc/redhat-release |cut -d ' ' -f 1`

function print_good () {
    echo -e "\x1B[01;32m[+]\x1B[0m $1"
}

function print_error () {
    echo -e "\x1B[01;31m[-]\x1B[0m $1"
}

function install_configure() {

if [ $UID != "0" ]; then
	print_error "Please use the root user"
	exit 1
fi

if [[ $system != $syst_version ]]; then
    print_error "Not centos system"
    exit 1
else
     for i in ${rely[*]}; do
         if ! rpm -q "$i">/dev/null ; then
            yum -y install $i
         fi
     done

     easy_install pip && easy_install argparse

     for p in ${piprely[*]}; do
         if ! pip show "$p">/dev/null ; then
             pip install $p
         fi
     done

    echo "{
     \"server\":\"$serverip\",
     \"server_port\":$port,
     \"local_port\":1080,
     \"password\":\"$passwd\",
     \"timeout\":300,
     \"method\":\"$method\"
    }" >/etc/shadowsocks.json

    sed -i '8s/^    //g' /etc/shadowsocks.json
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
    command=ssserver -c /etc/shadowsocks.json
    autostart=true
    autorestart=true
    startsecs=3
    redirect_stderr=true
    stdout_logfile=/var/log/shadowsocks.log' >>/etc/supervisord.conf

    sed -i 's/^    //g' /etc/supervisord.conf

##### iptables 放行端口  #####

    iptables -I INPUT -p tcp --dport $port -j ACCEPT
    iptables -I INPUT -p udp --dport $port -j ACCEPT
    service iptables save
    service iptables restart

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

##### 安装Denyhosts防止SSH暴力破解和supervisor用于守护进程 #####

    #wget http://longshanren.net/auto_install_denyhosts.sh -O ~/auto_install_denyhosts.sh -O - | sh
    wget http://longshanren.net/soft/supervisord -O /etc/init.d/supervisord && chmod 755 /etc/init.d/supervisord || exit 1
    chkconfig --add supervisord
    chkconfig supervisord on
    ln -sf /etc/init.d/supervisord /usr/bin/sss
    sss start
    rm -rf DenyHosts-2.6  DenyHosts-2.6.tar.gz  auto_install_denyhosts.sh distribute-0.7.3.zip distribute-0.7.3
    echo ""
    print_good "*******************************************************************************************************"
    print_good ""
    print_good "            Shadowsocks successful installation"
    print_good ""
    print_good "            Server IP:  $serverip"
    print_good "            Port:       $port"
    print_good "            Password:   $passwd"
    print_good "            Method:     $method"
    print_good "            Local IP:   127.0.0.1"
    print_good "            Local port: 1080"
    print_good ""

function end_time() {
    end_year_month_day=`date +%-Y年%-m月%-d日`
    end_hours=`date +%-H`
    end_minute=`date +%-M`
    end_second=`date +%-S`
    print_good "                从 $begin_year_month_day $begin_hours:$begin_minute:$begin_second 开始，于 $end_year_month_day $end_hours:$end_minute:$end_second 完成."
    print_good ""
    print_good "            一共耗费了 $[$end_hours-begin_hours] 小时 $[$end_minute-begin_minute] 分钟 $[$end_second-$begin_second] 秒"|sed 's/\-//'
    print_good ""
    print_good "*******************************************************************************************************"
    echo ""
}
    
    begin_time;install_configure;end_time;rm -rf $0
