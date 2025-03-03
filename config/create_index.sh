#!/bin/bash

FILE="/usr/share/nginx/html/index.html"
BACKUP_FILE="/usr/share/nginx/html/index.html.bak"

clear
if [ -f "$FILE" ]; then
    if [ -f "$BACKUP_FILE" ]; then
        read -p "备份文件 $BACKUP_FILE 已存在，是否覆盖？(y/n): " choice
        if [ "$choice" = "y" ]; then
            mv -f "$FILE" "$BACKUP_FILE"
            echo "已覆盖 $BACKUP_FILE"
        else
            echo "未覆盖 $BACKUP_FILE，操作取消"
        fi
    else
        mv "$FILE" "$BACKUP_FILE"
        echo "已将 $FILE 备份为 $BACKUP_FILE"
    fi
else
    echo "$FILE 不存在，无需备份"
fi

cat > "$FILE" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome</title>
    <style>
        body, html {
            margin: 0;
            padding: 0;
            width: 100%;
            height: 100%;
            font-family: 'Arial', sans-serif;
            overflow: hidden;
        }

        body {
            background: linear-gradient(45deg, #ff0000, #ff7f00, #ffff00, #7fff00, #00ff00, #00ff7f, #00ffff, #007fff, #0000ff, #7f00ff, #ff00ff, #ff007f);
            background-size: 300% 300%;
            animation: gradient 10s ease infinite;
        }

        @keyframes gradient {
            0% { background-position: 0% 50%; }
            50% { background-position: 100% 50%; }
            100% { background-position: 0% 50%; }
        }

        .centered {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            text-align: center;
            color: white;
        }

        .centered h1 {
            font-size: 4em;
            background: -webkit-linear-gradient(45deg, #ff0000, #0000ff);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            animation: textGradient 3s ease infinite;
        }

        @keyframes textGradient {
            0% { background-position: 0% 50%; }
            50% { background-position: 100% 50%; }
            100% { background-position: 0% 50%; }
        }

        .button {
            padding: 15px 30px;
            font-size: 1.5em;
            color: white;
            background-color: rgba(0, 0, 0, 0.5);
            border: none;
            border-radius: 10px;
            cursor: pointer;
            transition: background-color 0.3s ease;
        }

        .button:hover {
            background-color: rgba(255, 255, 255, 0.5);
        }

        #ipDisplay {
            margin-top: 20px;
            font-size: 2em;
        }
    </style>
    <script>
        function showIp() {
            fetch('/ip')
                .then(response => response.text())
                .then(data => {
                    document.getElementById('ipDisplay').innerText = "Your IP address is: " + data;
                })
                .catch(error => console.error('Error fetching IP:', error));
        }
    </script>
</head>
<body>
    <div class="centered">
        <h1>Welcome to My Website</h1>
        <button class="button" onclick="showIp()">Click to Show IP Address</button>
        <p id="ipDisplay"></p>
    </div>
</body>
</html>
EOF

chmod 644 "$FILE"
chown www-data:www-data "$FILE"

nginx -s reload
echo "新的 index.html 已成功创建,Nginx 配置已重新加载"
