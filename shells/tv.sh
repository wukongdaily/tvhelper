#!/bin/bash
# 全局变量来标记是否已经执行一次性操作
executed_once=0
# 定义只执行一次的操作
execute_once() {
    if [ $executed_once -eq 0 ]; then
        executed_once=1
    fi
}

#判断是否为x86软路由
is_x86_64_router() {
    DISTRIB_ARCH=$(cat /etc/openwrt_release | grep "DISTRIB_ARCH" | cut -d "'" -f 2)
    if [ "$DISTRIB_ARCH" = "x86_64" ]; then
        return 0
    else
        return 1
    fi
}

##获取软路由型号信息
get_router_name() {
    if is_x86_64_router; then
        model_name=$(grep "model name" /proc/cpuinfo | head -n 1 | awk -F: '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//')
        echo "$model_name"
    else
        model_info=$(cat /tmp/sysinfo/model)
        echo "$model_info"
    fi
}

# 执行重启操作
do_reboot() {
    reboot
}
# 关机
do_poweroff() {
    poweroff
}

#提示用户要重启
show_reboot_tips() {
    reboot_code='do_reboot'
    show_whiptail_dialog "软路由重启提醒" "           您是否要重启软路由?" "$reboot_code"
}

#提示用户要关机
show_poweroff_tips() {
    poweroff_code='do_poweroff'
    show_whiptail_dialog "软路由重启提醒" "           您是否要关闭软路由?" "$poweroff_code"
}

#********************************************************

# 定义红色文本
RED='\033[0;31m'
# 无颜色
NC='\033[0m'
GREEN='\033[0;32m'
YELLOW="\e[33m"

# 菜单选项数组
declare -a menu_options
declare -A commands
menu_options=(
    "安装ADB"
    "连接ADB"
    "断开ADB"
    "一键修改NTP服务器地址"
    "安装订阅助手"
    "安装Emotn Store应用商店"
    "安装当贝市场"
    "向TV端输入文字(限英文)"
    "显示Netflix影片码率"
)

commands=(
    ["安装ADB"]="install_adb"
    ["连接ADB"]="connect_adb"
    ["断开ADB"]="disconnect_adb"
    ["一键修改NTP服务器地址"]="modify_ntp"
    ["安装订阅助手"]="install_subhelper_apk"
    ["安装Emotn Store应用商店"]="000"
    ["安装当贝市场"]="000"
    ["向TV端输入文字(限英文)"]="000"
    ["显示Netflix影片码率"]="000"
)





show_user_tips() {
    read -p "按 Enter 键继续..."
}

# 检查输入是否为整数
is_integer() {
    if [[ $1 =~ ^-?[0-9]+$ ]]; then
        return 0 # 0代表true/成功
    else
        return 1 # 非0代表false/失败
    fi
}

# 判断adb是否安装
check_adb_installed() {
    if opkg list-installed | grep -q "^adb "; then
        return 0 # 表示 adb 已安装
    else
        return 1 # 表示 adb 未安装
    fi
}

# 判断adb是否连接成功
check_adb_connected() {
    local devices=$(adb devices | awk 'NR>1 {print $1}' | grep -v '^$')
    # 检查是否有设备连接
    if [[ -n $devices ]]; then
        #adb已连接
        echo "$devices 已连接"
        return 0
    else
        #adb未连接
        echo "没有检测到已连接的设备。请先连接ADB"
        return 1
    fi
}
# 安装adb工具
install_adb() {
    # 调用函数并根据返回值判断
    if check_adb_installed; then
        echo "adb is ready"
    else
        echo "正在尝试安装adb"
        opkg update
        opkg install adb
    fi
}

# 连接adb
connect_adb() {
    install_adb
    # 动态获取网关地址
    gateway_ip=$(ip a show br-lan | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
    # 提取网关IP地址的前缀，假设网关IP是192.168.66.1，则需要提取192.168.66.
    gateway_prefix=$(echo $gateway_ip | sed 's/\.[0-9]*$//').

    echo "请输入电视盒子的ip地址(${gateway_prefix})的最后一段数字"
    read end_number
    if is_integer "$end_number"; then
        # 使用动态获取的网关前缀
        ip=${gateway_prefix}${end_number}
        echo -e "正在尝试连接ip地址为${ip}的电视盒子\n若首次使用或者还未授权USB调试\n请在盒子的提示弹框上点击 允许 按钮"
        adb disconnect
        adb connect ${ip}
        # 尝试通过 adb shell 回显一个字符串来验证连接
        sleep 2
        adb shell echo "ADB has successfully connected"
    else
        echo "错误: 请输入整数."
    fi
}

# 一键修改NTP服务器地址
modify_ntp() {
    # 获取连接的设备列表
    local devices=$(adb devices | awk 'NR>1 {print $1}' | grep -v '^$')

    # 检查是否有设备连接
    if [[ -n $devices ]]; then
        echo "已连接的设备：$devices"
        # 对每个已连接的设备执行操作
        for device in $devices; do
            adb -s $device shell settings put global ntp_server ntp3.aliyun.com
            echo "NTP服务器已经成功修改为 ntp3.aliyun.com"
        done
    else
        echo "没有检测到已连接的设备。请先连接ADB"
    fi
}

#断开adb连接
disconnect_adb() {
    install_adb
    adb disconnect
    echo "ADB 已经断开"
}

# 安装订阅助手
install_subhelper_apk() {
    wget -O subhelper.apk https://github.com/wukongdaily/tvhelper/raw/master/apks/subhelp14.apk
    if check_adb_connected; then
        # 使用 adb install 命令安装 APK，并捕获输出
        echo "正在推送和安装apk 请耐心等待..."
        install_result=$(adb install subhelper.apk 2>&1)
        # 检查输出中是否包含 "Success"
        if [[ $install_result == *"Success"* ]]; then
            echo "订阅助手 安装成功！"
        else
            echo "APK 安装失败：$install_result"
        fi
    else
        connect_adb
    fi
}


handle_choice() {
    local choice=$1
    # 检查输入是否为空
    if [[ -z $choice ]]; then
        echo -e "${RED}输入不能为空，请重新选择。${NC}"
        return
    fi

    # 检查输入是否为数字
    if ! [[ $choice =~ ^[0-9]+$ ]]; then
        echo -e "${RED}请输入有效数字!${NC}"
        return
    fi

    # 检查数字是否在有效范围内
    if [[ $choice -lt 1 ]] || [[ $choice -gt ${#menu_options[@]} ]]; then
        echo -e "${RED}选项超出范围!${NC}"
        echo -e "${YELLOW}请输入 1 到 ${#menu_options[@]} 之间的数字。${NC}"
        return
    fi

    # 执行命令
    if [ -z "${commands[${menu_options[$choice - 1]}]}" ]; then
        echo -e "${RED}无效选项，请重新选择。${NC}"
        return
    fi

    "${commands[${menu_options[$choice - 1]}]}"
}

show_menu(){
    clear
    echo "***********************************************************************"
    echo "*      遥控助手OpenWrt版 v1.0脚本        "
    echo "*      自动识别CPU架构 x86_64/Arm 均可使用         "
    echo -e "*      请确保电视盒子和OpenWrt路由器处于同一网段\n*      且电视盒子开启了USB调试模式(adb开关)         "
    echo "*      Developed by @wukongdaily        "
    echo "**********************************************************************"
    echo
    echo "*      当前的软路由型号: $(get_router_name)"
    echo
    echo "**********************************************************************"
    echo "请选择操作："
    for i in "${!menu_options[@]}"; do
        echo "$((i + 1)). ${menu_options[i]}"
    done
}


while true; do
    show_menu
    read -p "请输入选项的序号(输入q退出): " choice
    if [[ $choice == 'q' ]]; then
        break
    fi
    handle_choice $choice
    echo "按任意键继续..."
    read -n 1 # 等待用户按键
done




