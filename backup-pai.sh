#!/bin/sh
#####树莓派异地备份服务器端脚本 V0.4#####
#2018-03-06

#基础数据
MYSQL_USER=                 #数据库用户名   例：dbuser
MYSQL_PASS=                 #数据库密码     例：123456
WEB_DATA=                   #Web文件目录    例：/var/www
PCH_DATA=                   #如果需要排除备份某文件夹（例如缓存文件夹等）   例：/var/www/wp-content/cache
Backup_local_DIR=           #备份文件存储位置   例：/home/backup

#增量备份快照文件
Backup_snap=${Backup_local_DIR}/Backup.snap
#输出运行时间到log文件
date >> ${Backup_local_DIR}/hk_backup_run.log

#备份文件文件名
DataBakName=Data_$(date +%Y%m%d).tar.gz
WebBakName=Web_$(date +%Y%m%d).tar.gz
MD5File=MD5_$(date +%Y%m%d).md5

#备份开始时将备份状态标志置为False
echo "False" >              #备份状态标志位置 必须是可访问地址 例：/var/www/status.html
rm -f ${Backup_local_DIR}/FileName


#每周一进行整体备份
if [ $( date +%u  ) -eq "1" ] 
then
echo "\033[03m Monday delete Snap File \033[0m"
rm -f ${Backup_snap}
echo "$(date +%Y%m%d) rm SnapFile" >> ${Logfile}
fi

#压缩备份数据库
cd ${Backup_local_DIR}
echo  "\033[31m Export database \033[0m"
for db in `/usr/local/mysql/bin/mysql -u$MYSQL_USER -p$MYSQL_PASS -B -N -e 'SHOW DATABASES' | xargs`; do
    (/usr/local/mysql/bin/mysqldump -u$MYSQL_USER -p$MYSQL_PASS ${db} | gzip -9 - > ${db}.sql.gz)
done
echo "\033[31m Compressed database \033[0m"
tar vzcf $Backup_local_DIR/$DataBakName $Backup_local_DIR/*.sql.gz
rm -f $Backup_local_DIR/*.sql.gz


#压缩全站文件
echo "\033[31m Compressed Files \033[0m"
tar -g ${Backup_snap} -pzcf $Backup_local_DIR/$WebBakName --exclude=$PCH_DATA $WEB_DATA  #如果不需要排除路径，将 --exclude=$PCH_DATA 删除

#每周一进行全站备份时对备份文件进行分卷
if [ $( date +%u ) -eq "1" ]
then
echo "\033[03m Split File \033[03m"
BackupFileSize=`ls -l $Backup_local_DIR/$WebBakName | awk '{ print $5 }'`
SplitMB=500      #分卷大小 单位MB
SplitBype=`expr $SplitMB \* 1024`
SplitBit=`expr $SplitBype \* 1024`
SplitFileNum=`expr $BackupFileSize / $SplitBit`
if [ `expr $BackupFileSize % $SplitBit` -ne 0 ]
then
    SplitFileNum=`expr $SplitFileNum + 1`
fi
i=1
SkipBype=0
while [ $i -le $SplitFileNum ]
do
    echo "$WebBakName"_"$i" >> FileName
    dd if=$WebBakName of="$WebBakName"_"$i" bs=1024 count=$SplitBype skip=$SkipBype
    md5sum "$WebBakName"_"$i" >> $MD5File
    i=`expr $i + 1`
    SkipBype=`expr $SkipBype + $SplitBype`
done
    md5sum $DataBakName >> $MD5File
    echo $DataBakName >> FileName
    rm -f $WebBakName
fi
rm -f ${Backup_local_DIR}/BackupDone
if [ $( date +%u  ) -ne "1" ]
then
    echo ${DataBakName} >> FileName
    echo ${WebBakName}  >> FileName
    md5sum ${DataBakName} ${WebBakName} > ${MD5File}
fi
echo ${MD5File} >> FileName
chown vpsback:ftpgroup -R ${Backup_local_DIR}   #使用时将 vpsback:ftpgroup 替换成自己的FTP用户名和用户组 用户名:用户组
echo "ok" >    #将标志位设置为ok 必须是可访问地址 例：/var/www/status.html
echo "Backup complete"