#!/bin/bash
set -e
source constant.sh

help() {
	echo "aggregate-config.sh base config [configs ...]"
}
main() {
	if [ "$#" -lt 2 ]; then
		help
		exit 1
	fi
    tmp=$(mktemp)
    echo "Tmp config file: $tmp"

	# 初始化变量
	app="default_app"
	# 使用getopts解析参数
	while getopts ":a:" opt; do
		case $opt in
			a) app="$OPTARG"
			;;
			\?) echo "无效的选项: -$OPTARG" >&2
			;;
		esac
	done
	echo $app
	
	# 移除已解析的选项(-a 和 appche)
	if [ "$app" != "default_app" ]; then
		echo "-a option exists"
		shift
		shift
	fi

	# 获取剩余的参数作为configs
	# echo $@
	baseconfig=$1
	shift
	configs=$@
	# echo $configs
	for config in $configs; do
        echo "Collect config for $config"
		cat $config >>$tmp
	done

    tmp2=$(mktemp)
    echo "Filter with the $baseconfig"
	# use the original config to determine the value
	python3 assign-config-value.py $baseconfig $tmp >$tmp2

    echo "Merge with allnoconfig"
    cd $linux
    ./scripts/kconfig/merge_config.sh -n $tmp2 &>merge.log
	if [ "$app" != "default_app" ]; then
		cat $tmp2 > /Cozart/test/$app/$app.final.config
	fi
}

main $@
