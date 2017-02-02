#!/bin/bash
#Backup mysql par ftp
#Parametre de connexion a MySQL
echo
echo -- T E L M A  S.A --
echo -- Script de Restauration MySQL --
echo

Mysql_User="User"
Mysql_Paswd="Password"
Mysql_host="localhost"

#Configuration de pass sur serveur FTP
loginftp="User"
motdepassftp="Password"
host_ftp="xx.xx.xx.xx"

# Emplacemment du dossier de backup local
DEST="/home/archives/restaure"

#Rep ou on fou le sql
DEST_mysql="$DEST/mysql"

#Date de la restauration

read -p 'Entrez la date a laquel restaurer (format : JJ-MM-AAAA) : ' -n 10 DATE
echo
echo -e "\n Lancement de la restauration a la date du $DATE ..."
echo

#on cree le rep
[ ! -d $DEST_mysql ] && mkdir -p $DEST_mysql || :

## Conf des rep de backup pour le ftp
DIR_BACKUP_mysql=$DEST_mysql
DIR_DIST_BACKUP_mysql='/BACKUP/mysql/'

DBS=""

## Dowload des bases depuis SINFRA
echo
echo -- Dowload des bases depuis le serveur FTP --
echo
yafc $loginftp:$motdepassftp@$host_ftp <<**
cd $DIR_DIST_BACKUP_mysql
lcd $DIR_BACKUP_mysql
cd $DATE
get -rv *
bye
**

#On restaure
FILE="$DEST_mysql/zabbix.$DATE.gz"
#cd $DEST_mysql
echo
echo -- Decompression puis restauration -- 
echo -- Cette operation peut durer plusieurs minutes --
echo
gunzip $FILE
mysql -u $Mysql_User -h $Mysql_host -p$Mysql_Paswd zabbix < /home/archives/restaure/mysql/zabbix.$DATE
echo
echo -- Effacement des fichiers --
echo
rm -r /home/archives/restaure/mysql/
echo
echo -- Restauration Terminée --
echo
~
