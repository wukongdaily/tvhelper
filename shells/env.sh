#!/bin/sh
# MT3000/2500/6000 没有bash 需要先安装
# wget -O env.sh https://raw.githubusercontent.com/wukongdaily/tvhelper/master/shells/env.sh && chmod +x env.sh && ./env.sh
proxy=""
if [ $# -gt 0 ]; then
  proxy="https://mirror.ghproxy.com/"
fi
check_bash_installed() {
  if [ -x "/bin/bash" ]; then
    echo "downloading tv.sh ......"
  else
    echo "install bash env ......"
    opkg update
    opkg install bash
  fi
}


enter_main_menu() {
  wget -O tv.sh ${proxy}https://raw.githubusercontent.com/wukongdaily/tvhelper/master/shells/tv.sh && chmod +x tv.sh && ./tv.sh ${proxy}
}

check_bash_installed
enter_main_menu
