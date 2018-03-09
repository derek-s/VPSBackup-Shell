#!/bin/bash

LOCKFILE= #设置一个锁文件 路径需要带引号 例如 "/home/pi/vpsback/verify.tmp"

trap 'echo "rm lockfile!";rm -f ${LOCKFILE}; exit' 1 2 3 9 15

if [ -f $LOCKFILE ]
then
    echo "verify-pai.sh is Running!"
    exit 0
else
    touch $LOCKFILE
    chmod 600 $LOCKFILE
    echo "touch successed"
    verify-pai.sh    #执行下载脚本 带路径 例如/home/pi/vpsback/verify-pai.sh
    echo "download complete"
fi

rm -f $LOCKFILE

