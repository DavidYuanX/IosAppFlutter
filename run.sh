#!/bin/bash
cd "$(dirname "$0")"

CONFIG_FILE="lib/config/api_config.dart"

# 获取本机 IP 所在网段
get_network_prefix() {
    local ip
    if [[ "$OSTYPE" == "darwin"* ]]; then
        ip=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}')
    else
        ip=$(hostname -I | awk '{print $1}')
    fi
    echo "${ip%.*}"
}

# 扫描 8080 端口
scan_port_8080() {
    local prefix="$1"

    # 并行扫描，超时设为 1 秒
    for i in $(seq 1 254); do
        (
            if curl -s --connect-timeout 1 "http://${prefix}.${i}:8080" > /dev/null 2>&1; then
                echo "${prefix}.${i}"
            fi
        ) &
    done
    wait
}

# 更新配置文件
update_config() {
    local new_ip="$1"
    local new_url="http://${new_ip}:8080"

    # 使用 sed 更新 baseUrl
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|static const String baseUrl = '[^']*'|static const String baseUrl = '${new_url}'|g" "$CONFIG_FILE"
    else
        sed -i "s|static const String baseUrl = '[^']*'|static const String baseUrl = '${new_url}'|g" "$CONFIG_FILE"
    fi

    echo "已更新 API 地址: ${new_url}"
}

# 主流程
echo "=== 自动检测后端服务 ==="
prefix=$(get_network_prefix)

if [ -n "$prefix" ]; then
    echo "正在扫描 ${prefix}.0/24 网段的 8080 端口..."
    found_ip=$(scan_port_8080 "$prefix" | head -1)

    if [ -n "$found_ip" ]; then
        update_config "$found_ip"
    else
        echo "未找到运行中的后端服务，使用当前配置"
    fi
else
    echo "无法获取网段信息，使用当前配置"
fi

echo "=== 启动 Flutter 应用 ==="
flutter run -d Chrome