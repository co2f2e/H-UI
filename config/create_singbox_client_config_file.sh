#!/bin/bash
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
RESET='\033[0m'

green() {
	echo -e "${GREEN}${1}${RESET}"
}

red() {
	echo -e "${RED}${1}${RESET}"
}

yellow() {
	echo -e "${YELLOW}${1}${RESET}"
}

clear
OUTPUT_FILE="./singbox_tun.json"
echo
yellow "此脚本仅适用于hysteria2协议节点!!!"
echo
while true; do
read -p "$(green '请输入Hysteria2节点的数量: ')" SERVER_COUNT
if ! [[ "$SERVER_COUNT" =~ ^[1-9][0-9]*$ ]]; then
  red "输入有误，请输入大于0的整数"
  echo
else
  break
fi
done
while true; do
read -p "$(green '请设置上传速度(mbps): ')" UP_MBPS
if ! [[ "$UP_MBPS" =~ ^[1-9][0-9]{0,3}$ ]]; then
  red "输入有误，请输入1~9999有效的数字"
  echo
else
  break
fi
done
while true; do
read -p "$(green '请设置下载速度(mbps): ')" DOWN_MBPS
if ! [[ "$DOWN_MBPS" =~ ^[1-9][0-9]{0,3}$ ]]; then
  red "输入有误，请输入1~9999有效的数字"
  echo
else
  break
fi
done
echo
declare -a NAMES
declare -a SERVERS
declare -a PORTS
declare -a PASSWORDS
for (( i=1; i<=SERVER_COUNT; i++ ))
do
  read -p "$(green "请设置节点${i}的自定义名称: ")" NAME
    if [[ " ${NAMES[@]} " =~ " ${NAME} " ]]; then
      red "此名称已经存在，请重新设置"
      ((i--))
      echo
      continue
    fi
  NAMES[i]=$NAME
  read -p "$(green "请输入节点${i}的地址: ")" SERVER
  SERVERS[i]=$SERVER
  read -p "$(green "请输入节点${i}的端口号: ")" PORT
  PORTS[i]=$PORT
  read -p "$(green "请输入节点${i}的密码: ")" PASSWORD
  PASSWORDS[i]=$PASSWORD
  echo
done
generate_outbounds() {
  local result=""
  for (( i=1; i<=SERVER_COUNT; i++ )); do
    if [[ $i -lt $SERVER_COUNT ]]; then
      result+="\"${NAMES[i]}\", "
    else
      result+="\"${NAMES[i]}\""
    fi
  done
  echo "$result" 
}
cat > "$OUTPUT_FILE" <<EOF
{
  "log": {
    "disabled": false,
    "level": "debug",
    "timestamp": true
  },
  "dns": {
    "servers": [
      {"tag": "dns_direct", "address": "223.5.5.5", "address_strategy": "ipv4_only", "strategy": "ipv4_only", "detour": "🎯 全球直连"},
      {"tag": "dns_proxy", "address": "tls://8.8.8.8", "address_strategy": "ipv4_only", "strategy": "ipv4_only", "detour": "🚀 节点选择"}
    ],
    "rules": [
      {"outbound": "any", "action": "route", "server": "dns_direct", "disable_cache": true},
      {"rule_set": "geosite-cn", "action": "route", "server": "dns_direct"},
      {"rule_set": "geosite-geolocation-!cn", "action": "route", "server": "dns_proxy"}
    ],
    "final": "dns_proxy",
    "strategy": "ipv4_only"
  },
  "inbounds": [
    {
      "type": "tun",
      "address": "172.19.0.1/30",
      "mtu": 9000,
      "auto_route": true,
      "auto_redirect": false,
      "strict_route": true,
      "stack": "system",
      "platform": {
        "http_proxy": {
          "enabled": false,
          "server": "127.0.0.1",
          "server_port": 2080
        }
      }
    },
    {
      "type": "mixed",
      "listen": "127.0.0.1",
      "listen_port": 2080,
      "sniff": true,
      "users": []
    }
  ],
  "outbounds": [
    { "tag": "🚀 节点选择", "type": "selector", "outbounds": [$(generate_outbounds)] },
    { "tag": "📹 YouTube", "type": "selector", "outbounds": ["🚀 节点选择", $(generate_outbounds)] },
    { "tag": "🤖 OpenAI", "type": "selector", "outbounds": [$(generate_outbounds)] },
    { "tag": "🍀 Google", "type": "selector", "outbounds": ["🚀 节点选择", $(generate_outbounds)] },
    { "tag": "👨‍💻 Github", "type": "selector", "outbounds": ["🚀 节点选择", $(generate_outbounds)] },
    { "tag": "🪟 Microsoft", "type": "selector", "outbounds": ["🚀 节点选择", $(generate_outbounds), "🎯 全球直连"] },
    { "tag": "🐬 OneDrive", "type": "selector", "outbounds": ["🚀 节点选择", $(generate_outbounds)] },
    { "tag": "🎵 TikTok", "type": "selector", "outbounds": ["🚀 节点选择", $(generate_outbounds)] },
    { "tag": "🎥 Netflix", "type": "selector", "outbounds": ["🚀 节点选择", $(generate_outbounds)] },
    { "tag": "📲 Telegram", "type": "selector", "outbounds": ["🚀 节点选择", $(generate_outbounds)] },
    { "tag": "🍏 Apple", "type": "selector", "outbounds": ["🎯 全球直连", "🚀 节点选择", $(generate_outbounds)] },
    { "tag": "🐠 漏网之鱼", "type": "selector", "outbounds": ["🚀 节点选择","🎯 全球直连"] },
    { "tag": "🎯 全球直连", "type": "direct" },
EOF
for (( i=1; i<=SERVER_COUNT; i++ ))
do
cat >> "$OUTPUT_FILE" <<EOF
      {
      "tag": "${NAMES[i]}",
      "server": "${SERVERS[i]}",
      "server_port": ${PORTS[i]},
      "type": "hysteria2",
      "up_mbps": ${UP_MBPS},
      "down_mbps": ${DOWN_MBPS},
      "password": "${PASSWORDS[i]}",
      "tls": {
        "insecure": false,
        "enabled": true
      },
      "tcp_fast_open": false
    }$( [[ $i -lt $SERVER_COUNT ]] && echo "," || echo "")
EOF
done
cat >> "$OUTPUT_FILE" <<EOF
  ],
  "route": 
 {
   "auto_detect_interface": true,
   "final": "🐠 漏网之鱼",
   "rules": 
   [
     {"action": "sniff"},
     {"protocol": "dns", "action": "hijack-dns"},
     {"clash_mode": "Direct", "outbound": "🎯 全球直连"},
     {"clash_mode": "Global", "outbound": "🚀 节点选择"},
     {"domain": ["clash.razord.top", "yacd.metacubex.one", "yacd.haishan.me", "d.metacubex.one"], "action": "route", "outbound": "🎯 全球直连"},
     {"rule_set": "geosite-private", "action": "route", "outbound": "🎯 全球直连"},
     {"rule_set": "geosite-chat", "action": "route", "outbound": "🤖 OpenAI"},
     {"rule_set": "geosite-youtube", "action": "route", "outbound": "📹 YouTube"},
     {"rule_set": "geosite-github", "action": "route", "outbound": "👨‍💻 Github"},
     {"rule_set": ["geosite-google", "geoip-google"], "action": "route", "outbound": "🍀 Google"},
     {"rule_set": ["geosite-telegram", "geoip-telegram"], "action": "route", "outbound": "📲 Telegram"},
     {"rule_set": "geosite-tiktok", "action": "route", "outbound": "🎵 TikTok"},
     {"rule_set": ["geosite-netflix", "geoip-netflix"], "action": "route", "outbound": "🎥 Netflix"},
     {"rule_set": ["geosite-apple", "geoip-apple"], "action": "route", "outbound": "🍏 Apple"},
     {"rule_set": "geosite-onedrive", "action": "route", "outbound": "🐬 OneDrive"},
     {"rule_set": "geosite-microsoft", "action": "route", "outbound": "🪟 Microsoft"},
     {"rule_set": "geosite-geolocation-!cn", "action": "route", "outbound": "🚀 节点选择"},
     {"rule_set": ["geoip-cn", "geosite-cn"], "action": "route", "outbound": "🎯 全球直连"}
   ],
    "rule_set": [
      { "tag": "geosite-chat", "type": "remote", "format": "binary", "url": "https://ghp.ci/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo/geosite/category-ai-chat-!cn.srs", "download_detour": "🎯 全球直连" },
      { "tag": "geosite-youtube", "type": "remote", "format": "binary", "url": "https://ghp.ci/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo/geosite/youtube.srs", "download_detour": "🎯 全球直连" },
      { "tag": "geosite-google", "type": "remote", "format": "binary", "url": "https://ghp.ci/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo/geosite/google.srs", "download_detour": "🎯 全球直连" },
      { "tag": "geosite-github", "type": "remote", "format": "binary", "url": "https://ghp.ci/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo/geosite/github.srs", "download_detour": "🎯 全球直连" },
      { "tag": "geosite-telegram", "type": "remote", "format": "binary", "url": "https://ghp.ci/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo/geosite/telegram.srs", "download_detour": "🎯 全球直连" },
      { "tag": "geosite-tiktok", "type": "remote", "format": "binary", "url": "https://ghp.ci/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo/geosite/tiktok.srs", "download_detour": "🎯 全球直连" },
      { "tag": "geosite-netflix", "type": "remote", "format": "binary", "url": "https://ghp.ci/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo/geosite/netflix.srs", "download_detour": "🎯 全球直连" },
      { "tag": "geosite-apple", "type": "remote", "format": "binary", "url": "https://ghp.ci/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo/geosite/apple.srs", "download_detour": "🎯 全球直连" },
      { "tag": "geosite-microsoft", "type": "remote", "format": "binary", "url": "https://ghp.ci/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo/geosite/microsoft.srs", "download_detour": "🎯 全球直连" },
      { "tag": "geosite-onedrive", "type": "remote", "format": "binary", "url": "https://ghp.ci/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo/geosite/onedrive.srs", "download_detour": "🎯 全球直连" },
      { "tag": "geosite-geolocation-!cn", "type": "remote", "format": "binary", "url": "https://ghp.ci/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo/geosite/geolocation-!cn.srs", "download_detour": "🎯 全球直连" },
      { "tag": "geosite-cn", "type": "remote", "format": "binary", "url": "https://ghp.ci/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo/geosite/cn.srs", "download_detour": "🎯 全球直连" },
      { "tag": "geosite-private", "type": "remote", "format": "binary", "url": "https://ghp.ci/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo/geosite/private.srs", "download_detour": "🎯 全球直连" },   
      { "tag": "geoip-google", "type": "remote", "format": "binary", "url": "https://ghp.ci/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo/geoip/google.srs", "download_detour": "🎯 全球直连" },
      { "tag": "geoip-telegram", "type": "remote", "format": "binary", "url": "https://ghp.ci/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo/geoip/telegram.srs", "download_detour": "🎯 全球直连" },     
      { "tag": "geoip-netflix", "type": "remote", "format": "binary", "url": "https://ghp.ci/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo/geoip/netflix.srs", "download_detour": "🎯 全球直连" },     
      { "tag": "geoip-apple", "type": "remote", "format": "binary", "url": "https://ghp.ci/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo-lite/geoip/apple.srs", "download_detour": "🎯 全球直连" },
      { "tag": "geoip-cn", "type": "remote", "format": "binary", "url": "https://ghp.ci/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo/geoip/cn.srs", "download_detour": "🎯 全球直连" },
      { "tag": "geoip-private", "type": "remote", "format": "binary", "url": "https://ghp.ci/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo/geoip/private.srs", "download_detour": "🎯 全球直连" }
    ]
  }
}
EOF
yellow "配置文件已生成路径如下：$OUTPUT_FILE"
