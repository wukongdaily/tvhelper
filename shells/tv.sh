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

# 分页大小，表示每页显示的菜单选项数量
PAGE_SIZE=6
# 当前页数
current_page=1
# 菜单选项数组
menu_options=(
    "安装ADB"
    "连接ADB"
    "一键修改NTP服务器地址"
    "安装订阅助手"
    "安装Emotn Store应用商店"
    "向TV端输入文字(限英文)"
    "显示Netflix影片码率"
    "等待开发7"
    "等待开发8"
    "等待开发9"
    "等待开发10"
    "等待开发11"
    "等待开发12"
    "等待开发13"
    "等待开发14"
    "等待开发15"
    "等待开发16"
)

# 计算总页数
total_pages=$(((${#menu_options[@]} + PAGE_SIZE - 1) / PAGE_SIZE))

# 显示菜单
show_menu_page() {
    local start=$((PAGE_SIZE * (current_page - 1)))
    local end=$((start + PAGE_SIZE - 1))

    for ((i = start; i <= end; i++)); do
        if [ $i -lt ${#menu_options[@]} ]; then
            echo "$((i + 1)). ${menu_options[i]}"
        fi
    done
}

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

# 安装adb工具
install_adb() {
    # 调用函数并根据返回值判断
    if check_adb_installed; then
        echo "ADB 已安装,您可以执行连接ADB了。"
    else
        echo "正在尝试安装adb"
        opkg update
        opkg install adb
    fi
}

# 连接adb
connect_adb() {
    if check_adb_installed; then
        echo "OK"
    else
        echo "正在尝试安装adb"
        opkg update
        opkg install adb
    fi
    # 动态获取网关地址
    gateway_ip=$(ip a show br-lan | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
    # 提取网关IP地址的前缀，假设网关IP是192.168.66.1，则需要提取192.168.66.
    gateway_prefix=$(echo $gateway_ip | sed 's/\.[0-9]*$//').

    echo "请输入电视盒子的ip地址(${gateway_prefix})的最后一段"
    read end_number
    if is_integer "$end_number"; then
        # 使用动态获取的网关前缀
        ip=${gateway_prefix}${end_number}
        echo "您输入的地址为${ip},正在连接盒子,请在盒子上点击 允许 按钮"
        adb connect ${ip}
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
            echo "正在修改设备 $device 的NTP服务器为ntp3.aliyun.com"
            adb -s $device shell settings put global ntp_server ntp3.aliyun.com
        done
    else
        echo "没有检测到已连接的设备。请先连接ADB"
    fi
}


while true; do
    clear
    execute_once
    echo "***********************************************************************"
    echo "*      遥控助手OpenWrt版 v1.0脚本        "
    echo "*      自动识别CPU架构 x86_64/Arm 均可使用         "
     echo "*     请确保电视盒子和软路由同一网段且电视盒子开启了USB调试模式(adb开关)         "
    echo "*      Developed by @wukongdaily        "
    echo "**********************************************************************"
    echo
    echo "*      当前的软路由型号: $(get_router_name)"
    echo
    echo "**********************************************************************"
    echo
    show_menu_page
    echo
    echo "***********************************************************************"
    echo "N: 下一页  B: 上一页  Q: 退出  R: 重启  P: 关机  第$current_page""页 / 总页数$total_pages"
    echo "***********************************************************************"
    echo
    read -p "请选择一个选项 (N/B/Q/R/P 不分大小写) : " choice

    case $choice in

    1)
        #安装ADB
        install_adb
        show_user_tips
        ;;
    2)
        #连接ADB
        connect_adb
        show_user_tips
        ;;
    3)
        #一键修改NTP服务器地址
        modify_ntp
        show_user_tips
        ;;

    4)
        show_user_tips
        ;;
    5)
        show_user_tips
        ;;
    6)
        echo
        show_user_tips
        ;;
    7)
        echo
        show_user_tips
        ;;
    8)
        echo
        show_user_tips
        ;;
    9)
        echo
        show_user_tips
        ;;
    10)
        echo
        show_user_tips
        show_reboot_tips
        ;;
    11)
        echo
        show_user_tips
        ;;
    [Nn])
        # 切换到下一页
        if [ $current_page -lt $total_pages ]; then
            current_page=$((current_page + 1))
        else
            echo
            echo "已经是最后一页了。"
            echo
            show_user_tips
        fi
        ;;
    [Bb])
        # 切换到上一页
        if [ $current_page -gt 1 ]; then
            current_page=$((current_page - 1))
        else
            echo
            echo "已经是第一页了。"
            echo
            show_user_tips
        fi
        ;;
    [Qq])
        echo
        echo "您已退出,欢迎下次再来"
        exit 0
        ;;
    [Rr])
        echo
        show_reboot_tips
        ;;
    [Pp])
        echo
        show_poweroff_tips
        ;;
    *)
        echo "无效选项，请重新选择。"
        ;;
    esac
done
