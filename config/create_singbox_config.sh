#!/bin/bash

clear

OUTPUT_FILE="./singbox.json"

read -p "请输入服务器的数量: " SERVER_COUNT

if ! [[ "$SERVER_COUNT" =~ ^[0-9]+$ ]]; then
  echo "请输入一个有效的数字！"
  exit 1
fi

declare -a NAMES
declare -a SERVERS
declare -a PORTS
declare -a PASSWORDS

for (( i=1; i<=SERVER_COUNT; i++ ))
do
  read -p "请输入节点${i}的自定义名称: " NAME
  NAMES[i]=$NAME

  read -p "请输入节点${i}的服务器地址: " SERVER
  SERVERS[i]=$SERVER
  
  read -p "请输入节点${i}的端口号: " PORT
  PORTS[i]=$PORT
  
  read -p "请输入节点${i}的密码: " PASSWORD
  PASSWORDS[i]=$PASSWORD

  echo "第 $i 个服务器信息已保存：地址=$SERVER, 端口=$PORT, 密码=$PASSWORD"
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
  echo "$result"  # 返回结果
}

# JSON 模板内容
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
          "enabled": true,
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
    { "tag": "🎯 全球直连", "type": "direct" }
EOF
for (( i=1; i<=SERVER_COUNT; i++ ))
do
cat >> "$OUTPUT_FILE" <<EOF
      {
      "tag": "${NAMES[i]}",
      "server": "${SERVERS[i]}",
      "server_port": ${PORTS[i]},
      "type": "hysteria2",
      "up_mbps": 70,
      "down_mbps": 100,
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


echo "配置文件已生成，路径：$OUTPUT_FILE"
