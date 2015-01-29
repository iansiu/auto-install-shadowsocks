# auto-install-shadowsocks


######	auto_install shadowsocks                  ######
######  By:iansiu                                 ######
######  Written:Thu 29 Jan 2015 08:52:21 PM CST   ######
######  Feedback: youweixiao@163.com 

    因为在学历Linux，加上自己也要用，就顺手整了个，适用于CentOS 6.5 和 CentOS 6.6。
    这个shell脚本安装的是Python版本的Shadowsocks，不适用于其它版本，整合了autoban掉IP的功能，顺便加了iptables保存防火墙规则，和在ban掉IP的同时发邮箱到指定的邮箱。

    使用方法：sh scripts 或是 chmod 755 scripts 然后./scripts

    发信箱和收信箱在代码里改，很简单的，123456@qq.com是收信箱，doujingyx309@163.com是发信箱和密码也要填写，代码里都有注释，总共不超过5行，如果没有收到邮件，请检查是不是在垃圾邮箱中。
