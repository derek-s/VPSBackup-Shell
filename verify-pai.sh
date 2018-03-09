#!/bin/bash
#树莓派下载备份、验证、删除数据

#FTP工作信息
FTPServer=      #vps地址，IP/域名
FTPUser=        #ftp登陆用户名
FTPPass=        #ftp登录密码

#工作路径
BackPath=       #备份文件在树莓派上的存储路径 例：/mnt/vpsback 

date >> ${BackPath}/run_log.log

rm -f ${BackPath}/FileName
rm -f ${BackPath}/BackupDone

#IDCName 用于邮件标题，可以自行更改
IDCName=VPSBackup_$(date +%Y%m%d)

mailcontent=Mail_$(date +%Y%m%d)
DataBakName=Data_$(date +%Y%m%d).tar.gz
WebBakName=Web_$(date +%Y%m%d).tar.gz
MD5FileName=MD5_$(date +%Y%m%d).md5
MAIL_TO=    #邮箱地址 用于接收本脚本运行日志

date >> $mailcontent

rm -f ${BackPath}/${MD5FileName}

#获取远程服务器状态
backstatus=`curl ` #curl后跟backup-pai内设置的标志位访问位置，例如 http://www.abc.com/status.html
cd ${BackPath}
echo $backstatus
if [ "$backstatus" = ok ]
echo $backstatus >> $mailcontent
then
    echo "Download FileName File"
    lftp "$FTPUser:$FTPPass"@"$FTPServer" << END
    get FileName
    quit
END
echo "download BackupFileName File done" >> $mailcontent
for line in `cat FileName`
do
    echo $line
    lftp "$FTPUser:$FTPPass"@"$FTPServer" << END
    get "$line"
    quit
END
done
#rm -rf FileName

cat $MD5FileName | while read -r line
do
  ren=0
  while [[ $ren -lt 10 ]]
  do
    MD5_Checkline=$(echo "$line" | md5sum -c)
    MD5_FileName=$(echo "$MD5_Checkline" | cut -d":" -f1)
    MD5_Status=$(echo "$MD5_Checkline" | awk '{print $2}')
    if [ "$MD5_Status" = OK ]
    then
      echo $MD5_Checkline >> $mailcontent
      lftp "$FTPUser:$FTPPass"@"$FTPServer" << END
      rm "$MD5_FileName"
      quit
END
    break
    fi
    if [ "$MD5_Status" != OK ]
    rm -rf ${MD5_FileName}
    echo "delete $MD5_FileName" >> $mailcontent
    then
      echo "redownload $MD5_FileName" >> $mailcontent
      lftp "$FTPUser:$FTPPass"@"$FTPServer" << END
      get "$MD5_FileName"
      quit
END
    fi
    ren=`expr $ren + 1`
    done
done
echo "done" > "$BackPath"/BackupDone
date +%Y/%m/%d-%H:%M:%S >> $mailcontent
echo "Backup complete" >> $mailcontent
lftp "$FTPUser:$FTPPass"@"$FTPServer" << END
put BackupDone
rm "$MD5FileName"
END
echo "磁盘使用情况" >> $mailcontent
df -lh $BackPath >> $mailcontent
mutt $MAIL_TO -i $mailcontent -s "$IDCName 树莓派备份报告"
rm -f $mailcontent
fi