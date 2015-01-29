我的邮箱：youweixiao@163.com


因为在学习Linux，加上自己也要用，就顺手整了个，适用于CentOS 6.5 和 CentOS 6.6。

其实主要是这里托管代码比较方便才放在这里，算不上什么项目，都是些垃圾代码，当然如果能帮助到你，我会很荣幸的。

这个shell脚本安装的是Python版本的Shadowsocks，不适用于其它版本，整合了autoban掉IP的功能，顺便加了iptables保存防火墙规则，和在ban掉IP的同时发邮件到指定的邮箱。

使用方法：sh scripts 或是 chmod 755 scripts 然后./scripts

发信箱和收信箱在代码里改，很简单的，123456@qq.com是收信箱，doujingyx309@163.com是发信箱，密码也要填写，代码里都有注释，总共不超过5行，如果没有收到邮件，请检查是不是在垃圾邮箱中。
