#!/bin/bash

BackPath=#备份文件地址 需与backup-pai内一致

date >> ${BackPath}/hk_check_log.log
backstatus=`cat ${BackPath}/BackupDone`
if [ "$backstatus" == done ]
then
    echo "False" > #备份状态标志位置 必须是可访问地址 该行示例：echo "False" > /var/www/backstatus.html 需与backup-pai内一致
fi
