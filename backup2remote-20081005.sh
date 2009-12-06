#!/bin/sh
RSYNC=/usr/bin/rsync
SSH=/usr/bin/ssh
#KEY=/home/localuser/.ssh /id_rsa
#RUSER=developer
#RHOST=211.166.10.154
#RPATH=/home/developer/ubuntu
#LPATH=/home/broader/develop/R@K

#$RSYNC   -avzur  --delete --progress  /usr/lib/python2.5/site-packages/roundup/gui /home/broader/develop/R@K/MMS
#$RSYNC   -avzur  --delete --progress  /usr/lib/python2.5/site-packages/roundup/ajax  /home/broader/develop/R@K/CMS/roundup_scripts

# back to  usb disk
mount /dev/sdb1 /mnt/usb
$RSYNC   -avzur  --delete --progress /home/broader/develop/R@K /mnt/usb


#$RSYNC -avzur --delete  --progress -e  $SSH  $LPATH  $RUSER@$RHOST:$RPATH 

# Shinepo website rsync
#R_SHINEPO=/home/developer
#L_SHINEPO=/home/broader/develop/R@K/OA/liujianguo/remote/shinepo
#$RSYNC -avzur --delete  --progress -e  $SSH  $L_SHINEPO  $RUSER@$RHOST:$R_SHINEPO
