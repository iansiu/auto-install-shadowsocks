仅适用于CentOS 6

1、会安装denyhosts，用于防止ssh暴力破解。

2、会安装supervisord，用户守护shadowsocks进程，挂了自动重启。

3、安装方法如下：

wget http://www.longshanren.net/soft/autoss.sh -O - | sh

使用方法：

启动：sss start  

重启：sss restart  

关闭：sss stop  

状态：sss status  

重新加载：sss force-reload  



不需要设置开机启动，scripts已经自动设置了。
