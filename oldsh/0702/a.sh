#!/bin/bash

#====================================================
# 一键搭建基于 caddy 的 https(h2) 代理 [ debian 8 ]
#====================================================



#获取配置信息
user="$1"
pass="$2"
domain="$3"
website="$4"



#配置端口和临时根域名
#:::::::::::::::::::::::::::::::::::::

port="443"
domain_root="ip.c2ray.ml"

#:::::::::::::::::::::::::::::::::::::



#设置代理信息
set_proxy_info(){

echo "----------------------------------------------------------"
echo "正在生成代理信息"
echo "----------------------------------------------------------"

#设置默认用户名
if [ ! ${user} ]; then
user="admin"
fi

#设置默认随机密码
if [ ! ${pass} ]; then
pass=`cat /dev/urandom | head -n 10 | md5sum | head -c 8`
fi

#生成默认域名
if [ ! ${domain} ]; then
rm -rf local_ip.txt && touch local_ip.txt
echo `curl -4 ip.sb` >> local_ip.txt && sed -i "s/\./\-/g" "local_ip.txt"
domain="$(cat local_ip.txt).${domain_root}" && rm -rf local_ip.txt
fi

#设置默认随机伪装网站
set_website_num

}
set_website_num(){

sitenum=`shuf -n 1 -e 1 2 3 4 5 6 7 8`
if [[ ! ${website} ]] && [[ ${sitenum} -eq 1 ]]; then
website="www.ibm.com"
elif [[ ! ${website} ]] && [[ ${sitenum} -eq 2 ]]; then
website="www.stenabulk.com"
elif [[ ! ${website} ]] && [[ ${sitenum} -eq 3 ]]; then
website="www.qualcomm.com"
elif [[ ! ${website} ]] && [[ ${sitenum} -eq 4 ]]; then
website="tw.longchamp.com"
elif [[ ! ${website} ]] && [[ ${sitenum} -eq 5 ]]; then
website="www.apple.com"
elif [[ ! ${website} ]] && [[ ${sitenum} -eq 6 ]]; then
website="www.rodesk.com"
elif [[ ! ${website} ]] && [[ ${sitenum} -eq 7 ]]; then
website="www.adidas.com.cn"
elif [[ ! ${website} ]] && [[ ${sitenum} -eq 8 ]]; then
website="www.frontlynk.com"
fi

}



#在menu下设置代理信息
menu_proxy_info(){

echo "按照提示依次设置代理的自定义用户名密码 自定义域名 自定义伪装站点"
echo "如使用默认值（或随机值） 请留空 直接按回车"
echo ""

stty erase '^H' && read -e -p "设置代理用户名：" user
if [ ! ${user} ]; then
user="admin"
fi

stty erase '^H' && read -e -p "设置代理密码：" pass
if [ ! ${pass} ]; then
pass=`cat /dev/urandom | head -n 10 | md5sum | head -c 8`
fi

stty erase '^H' && read -e -p "设置自定义域名：" domain
if [ ! ${domain} ]; then
rm -rf local_ip.txt && touch local_ip.txt
echo `curl -4 ip.sb` >> local_ip.txt && sed -i "s/\./\-/g" "local_ip.txt"
domain="$(cat local_ip.txt).${domain_root}" && rm -rf local_ip.txt
fi

stty erase '^H' && read -e -p "要伪装成的网站：" website
if [ ! ${website} ]; then
set_website_num
fi
}




#储存配置信息
storage_proxy_info(){

rm -rf /usr/local/bin/proxy_info
mkdir /usr/local/bin/proxy_info

touch /usr/local/bin/proxy_info/username
cat <<EOF > /usr/local/bin/proxy_info/username
${user}
EOF

touch /usr/local/bin/proxy_info/password
cat <<EOF > /usr/local/bin/proxy_info/password
${pass}
EOF

touch /usr/local/bin/proxy_info/domain
cat <<EOF > /usr/local/bin/proxy_info/domain
${domain}
EOF

touch /usr/local/bin/proxy_info/port
cat <<EOF > /usr/local/bin/proxy_info/port
${port}
EOF

}



#读取配置信息
read_proxy_info(){

get_user="$(cat /usr/local/bin/proxy_info/username)"

get_pass="$(cat /usr/local/bin/proxy_info/password)"

get_domain="$(cat /usr/local/bin/proxy_info/domain)"

get_port="$(cat /usr/local/bin/proxy_info/port)"

}



#清除可能残余的caddy
clean_caddy(){

echo "----------------------------------------------------------"
echo "正在清除可能残余的caddy文件（如多次重装）"
echo "----------------------------------------------------------"

rm -rf /usr/local/bin/Caddyfile
rm -rf /usr/local/bin/proxy_info

}



#安装caddy
install_caddy(){

if [[ -e /usr/local/bin/caddy ]]; then

echo "----------------------------------------------------------"
echo "检测到本机已安装 caddy 跳过执行安装程序"
echo "----------------------------------------------------------"

systemctl stop caddy

caddy_tips="使用本机原有的 caddy 程序，如果代理不可用请先执行卸载后重装"

else

echo "----------------------------------------------------------"
echo "正在安装caddy主程序和代理相关插件"
echo "----------------------------------------------------------"

curl https://getcaddy.com | bash -s personal http.forwardproxy,http.proxyprotocol

caddy_tips="安装已完成，基于 caddy 的 https(h2) 代理（自带website伪装网站）"

fi

}



#配置caddy
config_caddy(){

echo "----------------------------------------------------------"
echo "正在配置Caddyfile"
echo "----------------------------------------------------------"

touch /usr/local/bin/Caddyfile

cat <<EOF > /usr/local/bin/Caddyfile
${domain}:${port} {
tls admin@${domain}
root /www
gzip
index index.html
forwardproxy {
    basicauth ${user} ${pass}
}
}
EOF

}



#开机自启动caddy
auto_caddy(){

echo "----------------------------------------------------------"
echo "正在配置caddy开机自启动"
echo "----------------------------------------------------------"

touch /etc/systemd/system/caddy.service

cat <<EOF > /etc/systemd/system/caddy.service
[Unit]
Description=Caddy_Server
After=network.target
Wants=network.target
[Service]
Type=simple
ExecStart=/usr/local/bin/caddy -conf=/usr/local/bin/Caddyfile -agree=true -ca=https://acme-v02.api.letsencrypt.org/directory
RestartPreventExitStatus=23
Restart=always
User=root
[Install]
WantedBy=multi-user.target
EOF

systemctl enable caddy

}



#安装伪装网站
website_caddy(){

echo "----------------------------------------------------------"
echo "正在安装静态伪装网站"
echo "----------------------------------------------------------"

rm -rf /www
mkdir /www

wget -c -r -np -k -L -p ${website}

mv ./*${website}*/* /www

rm -rf ./*${website}*

}



#重启caddy
restart_caddy(){

check_port

echo "----------------------------------------------------------"
echo "正在重启caddy载入配置文件"
echo "----------------------------------------------------------"

systemctl daemon-reload

systemctl restart caddy

}



#检测caddy是否运行
chack_caddy(){

if [[ -e /usr/local/bin/caddy ]]; then

status1_caddy="已安装"

else

status1_caddy="未安装"

fi

PIDS=`ps -ef | grep caddy | grep -v grep | awk '{print $2}'`

if [ ! ${PIDS} ]; then

status2_caddy="未运行"

else

status2_caddy="已运行"

fi

}



#检测域名是否已解析
check_domain(){

local_ip=`curl -4 ip.sb`
domain_ip=`ping ${domain} -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`

if [ "${local_ip}" == "${domain_ip}" ]; then
#if [[ $(echo ${local_ip}|tr '.' '+'|bc) -eq $(echo ${domain_ip}|tr '.' '+'|bc) ]];then

status_domain="解析已生效"

else

status_domain="解析未生效 请将自定义域名A记录解析至 ${local_ip} 后重启caddy"

fi
}



#检测端口是否被占用
check_port(){

if [[ 0 -eq `lsof -i:"80" | wc -l` ]];then

status_port80="80端口正常"

else

status_port80="80端口异常 可能被其它进程占用"

fi

if [[ 0 -eq `lsof -i:"${port}" | wc -l` ]];then

status_portssl="${port}端口正常"

else

status_portssl="${port}端口异常 可能被其它进程占用"

fi

}



#检测域名ssl证书
chack_ssl(){

if [[ -e ./.caddy/acme/acme-v02.api.letsencrypt.org/sites/${domain}/${domain}.key ]]; then

status_ssl="已安装"

else

status_ssl="未安装（新增域名可能需要等待数分钟）"

fi
}



#展示配置信息
show_proxy_info(){

chack_caddy
check_domain
chack_ssl

clear
echo "----------------------------------------------------------"
echo ":: 基于 caddy 的 https(h2) 代理（自带website伪装网站）::"
echo "----------------------------------------------------------"
echo ""
echo "代理协议：https"
echo ""
echo "代理服务器：${domain}"
echo "代理端口：${port}"
echo ""
echo "用户名：${user}"
echo "密码：${pass}"
echo ""
echo "----------------------------------------------------------"
echo ""
echo "当前caddy状态：[${status1_caddy}]-[${status2_caddy}]"
echo "当前域名状态：${status_domain}"
echo "当前端口状态：[${status_port80}]-[${status_portssl}]"
echo "当前ssl证书状态：${status_ssl}"
echo ""
echo "${caddy_tips}"
echo "安装路径：/usr/local/bin/ [caddy] [Caddyfile]"
echo "关联项目：https://c2ray.ml"
echo ""
}



#命令执行列表
main(){
set_proxy_info
clean_caddy
storage_proxy_info
install_caddy
config_caddy
auto_caddy
website_caddy
restart_caddy
show_proxy_info
}



#卸载caddy
if [ "${user}" == uninstall ]; then

systemctl stop caddy
systemctl disable caddy

rm -rf /usr/local/bin/Caddyfile
rm -rf /usr/local/bin/caddy
rm -rf /etc/systemd/system/caddy.service
rm -rf /www
rm -rf /usr/local/bin/proxy_info

chack_caddy

clear
echo "----------------------------------------------------------"
echo ":: 基于 caddy 的 https(h2) 代理（自带website伪装网站）::"
echo "----------------------------------------------------------"
echo ""
echo "caddy已卸载"
echo ""
echo "关联项目：https://c2ray.ml"
echo ""
echo "----------------------------------------------------------"
echo ""
echo "当前caddy状态：[${status1_caddy}]-[${status2_caddy}]"
echo ""
exit

fi



#查看当前代理账号信息
if [ "${user}" == showinfo ]; then

read_proxy_info
chack_caddy

domain="${get_domain}"
chack_ssl

clear
echo "----------------------------------------------------------"
echo ":: 基于 caddy 的 https(h2) 代理（自带website伪装网站）::"
echo "----------------------------------------------------------"
echo ""
echo "代理协议：https"
echo ""
echo "代理服务器：${get_domain}"
echo "代理端口：${get_port}"
echo ""
echo "用户名：${get_user}"
echo "密码：${get_pass}"
echo ""
echo "----------------------------------------------------------"
echo ""
echo "当前caddy状态：[${status1_caddy}]-[${status2_caddy}]"
echo "当前ssl证书状态：${status_ssl}"
echo ""
echo "如需要修改用户名密码 重复执行安装时相同的代码即可"
echo "安装路径：/usr/local/bin/ [caddy] [Caddyfile]"
echo "关联项目：https://c2ray.ml"
echo ""
exit

fi



#修改用户名密码
reset_password(){

echo ""
echo "按照提示依次重设代理的用户名密码"
echo "如使用默认值（或随机值） 请留空 直接按回车"
echo ""

stty erase '^H' && read -e -p "设置代理用户名：" user
if [ ! ${user} ]; then
user="admin"
fi

stty erase '^H' && read -e -p "设置代理密码：" pass
if [ ! ${pass} ]; then
pass=`cat /dev/urandom | head -n 10 | md5sum | head -c 8`
fi

touch /usr/local/bin/proxy_info/username
cat <<EOF > /usr/local/bin/proxy_info/username
${user}
EOF

touch /usr/local/bin/proxy_info/password
cat <<EOF > /usr/local/bin/proxy_info/password
${pass}
EOF

sed -i '/^    basicauth/c\    basicauth '"${user}"' '"${pass}"'' /usr/local/bin/Caddyfile

echo "----------------------------------------------------------"
echo "正在重启caddy载入配置文件"
echo "----------------------------------------------------------"

systemctl restart caddy

read_proxy_info
chack_caddy

clear
echo "----------------------------------------------------------"
echo ":: 基于 caddy 的 https(h2) 代理（自带website伪装网站）::"
echo "----------------------------------------------------------"
echo ""
echo "代理协议：https"
echo ""
echo "代理服务器：${get_domain}"
echo "代理端口：${get_port}"
echo ""
echo "用户名：${get_user}"
echo "密码：${get_pass}"
echo ""
echo "----------------------------------------------------------"
echo ""
echo "当前caddy状态：[${status1_caddy}]-[${status2_caddy}]"
echo ""
echo "安装路径：/usr/local/bin/ [caddy] [Caddyfile]"
echo "关联项目：https://c2ray.ml"
echo ""

}



#菜单模式menu
if [ "${user}" == menu ]; then

chack_caddy

clear
echo "----------------------------------------------------------"
echo ":: 基于 caddy 的 https(h2) 代理（自带website伪装网站）::"
echo "----------------------------------------------------------"
echo ""
echo "1.全自动一键安装（随机密码 自动临时域名 随机伪装站点）"
echo "2.自定义一键安装（自定义账号密码 自定义域名 自定义伪装站点）"
echo ""
echo "3.重启caddy"
echo "4.查看当前代理账号信息"
echo ""
echo "5.修改用户名密码"
echo "6.一键卸载"
echo ""
echo "7.彩蛋"
echo "8.退出"
echo ""
echo "----------------------------------------------------------"
echo ""
echo "当前caddy状态：[${status1_caddy}]-[${status2_caddy}]"
echo ""

stty erase '^H' && read -e -p "请输入：" menu_num

case ${menu_num} in

1)
bash <(curl -L -s git.io/a.sh)
;;

2)
menu_proxy_info
bash <(curl -L -s git.io/a.sh) ${user} ${pass} ${domain} ${website}
;;

3)
systemctl restart caddy
clear
echo "----------------------------------------------------------"
echo "已重启caddy进程 [5]秒钟后返回开始菜单"
echo "----------------------------------------------------------"
sleep 5
bash <(curl -L -s git.io/a.sh) menu
;;

4)
bash <(curl -L -s git.io/a.sh) showinfo
;;

5)
reset_password
;;

6)
bash <(curl -L -s git.io/a.sh) uninstall
;;

7)
bash <(curl -L -s git.io/a.sh) egg
;;

8)
exit
;;

*)
bash <(curl -L -s git.io/a.sh) menu
;;

esac
exit

fi



#彩蛋
if [[ "${user}" == egg ]] && [[ -e /usr/local/bin/Caddyfile ]]; then

echo "----------------------------------------------------------"
echo "正在安装彩蛋"
echo "----------------------------------------------------------"

read_proxy_info
chack_caddy

rm -rf /www
mkdir /www

wget -r -p -np -k https://chvin.github.io/react-tetris/
wget -r -p -np -k https://chvin.github.io/react-tetris/music.mp3

mv ./chvin.github.io/react-tetris/* /www

rm -rf ./chvin.github.io

clear
echo "----------------------------------------------------------"
echo ":: 基于 caddy 的 https(h2) 代理（自带website伪装网站）::"
echo "----------------------------------------------------------"
echo ""
echo "彩蛋安装完成 打开伪装网站查看"
echo "彩蛋地址：${get_domain}"
echo ""
echo "代理协议：https"
echo ""
echo "代理服务器：${get_domain}"
echo "代理端口：${get_port}"
echo ""
echo "用户名：${get_user}"
echo "密码：${get_pass}"
echo ""
echo "关联项目：https://c2ray.ml"
echo ""
echo "----------------------------------------------------------"
echo ""
echo "当前caddy状态：[${status1_caddy}]-[${status2_caddy}]"
echo ""
exit

elif [[ "${user}" == egg ]]; then

bash <(curl -L -s git.io/a.sh)
bash <(curl -L -s git.io/a.sh) egg
exit

fi



main


