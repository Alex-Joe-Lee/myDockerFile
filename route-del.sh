#!/bin/sh

# 指定路由规则文件的路径
ROUTES_FILE="route-del-linux.txt"

# 逐行读取路由规则文件并添加路由
while IFS= read -r line
do
    # 执行添加路由的命令
    $line
done < "$ROUTES_FILE"

