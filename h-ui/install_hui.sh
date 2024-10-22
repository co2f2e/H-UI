#!/bin/bash

clear
mkdir -p /usr/local/h-ui/
curl -fsSL https://github.com/jonssonyan/h-ui/releases/latest/download/h-ui-linux-amd64 -o /usr/local/h-ui/h-ui && chmod +x /usr/local/h-ui/h-ui
curl -fsSL https://raw.githubusercontent.com/jonssonyan/h-ui/main/h-ui.service -o /etc/systemd/system/h-ui.service
sed -i "s|^ExecStart=.*|ExecStart=/usr/local/h-ui/h-ui -p 8081|" "/etc/systemd/system/h-ui.service"
systemctl daemon-reload
systemctl enable h-ui
systemctl restart h-ui

echo
echo "登录方式：IP:PORT"
echo "面板端口：6812"
echo "用户名/密码：sysadmin"
echo
