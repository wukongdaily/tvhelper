#!/bin/bash
# 定义红色文本
RED='\033[0;31m'
# 无颜色
NC='\033[0m'
GREEN='\e[38;5;154m'
YELLOW="\e[93m"
BLUE="\e[96m"
# 赞助
sponsor() {
        if ! opkg list-installed | grep -q '^qrencode'; then
        opkg update 
        echo -e "${GREEN}........首次加载,请稍后........${NC}"
        opkg install qrencode >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo
        else
            echo "qrencode安装失败。"
        fi
    else
        echo
    fi
    echo -e "${GREEN}悟空的赞赏码如下⬇${BLUE}"
    echo
    qrencode -t ANSIUTF8 'https://gitee.com/wukongdaily/tvhelper-docker/raw/master/shells/image.jpg'
    echo
}