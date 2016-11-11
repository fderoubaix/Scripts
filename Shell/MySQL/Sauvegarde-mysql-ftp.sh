#!/bin/bash
#Backup mysql par ftp
Mysql_User="User"
Mysql_Paswd="Password"
Mysql_host="localhost"
# Emplacemment des different prog utilisé, laisser tel quel si vous n'avez rien bidouillé
MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"
CHOWN="$(which chown)"
CHMOD="$(which chmod)"
GZIP="$(which gzip)"

# Emplacemment du dossier de backup local
DEST="/home/archives/backup/"

#Rep ou on fou le sql
DEST_mysql="$DEST/mysql"

#Date du jour
NOW="$(date +"%d-%m-%Y")"

# Databases a ne pas sauvegarder separer par des espaces
IGGY=""

# On initialise les variables
FILE=""
DBS=""

#on cree le rep
[ ! -d $DEST_mysql ] && mkdir -p $DEST_mysql || :

#On limite l'acces au root uniquemment
#$CHOWN 0.0 -R $DEST_mysql
#$CHMOD 0600 $DEST_mysql

# On liste les bases de donnees
DBS="$($MYSQL -u $Mysql_User -h $Mysql_host -p$Mysql_Paswd -Bse 'show databases')"

for db in $DBS
do
    skipdb=-1
    if [ "$IGGY" != "" ];
    then
        for i in $IGGY
        do
            [ "$db" == "$i" ] && skipdb=1 || :
        done
    fi

    if [ "$skipdb" == "-1" ] ; then
        FILE="$DEST_mysql/$db.$NOW.gz"
        # On boucle, et on dump toutes les bases et on les compresse
        $MYSQLDUMP -u $Mysql_User -h $Mysql_host -p$Mysql_Paswd $db | $GZIP -9 > $FILE
    fi
done

#On compresse le dossier "files" de GLPI
tar -cvf /home/archives/backup/mysql/backup_files.tar /var/lib/glpi/files

#BACKUP des bases mysql par FTP
#nbre de jour de backup a conserver
j=7
j_a_delete=$(date +%d-%m-%Y --date "$j days ago")

## Conf des rep de backup pour le ftp
DIR_BACKUP_mysql=$DEST_mysql
DIR_DIST_BACKUP_mysql='/BACKUP/mysql/'

#Configuration de pass ftp
loginftp="User"
motdepassftp="Password"
host_ftp="xx.xx.xx.xx"

## Upload sur le ftp
yafc $loginftp:$motdepassftp@$host_ftp <<**
cd $DIR_DIST_BACKUP_mysql
lcd $DIR_BACKUP_mysql
mkdir $NOW
cd $NOW
put -r *
cd ..
rm -r $j_a_delete
bye
**

#On delete tout
cd $DEST_mysql
rm -r *
