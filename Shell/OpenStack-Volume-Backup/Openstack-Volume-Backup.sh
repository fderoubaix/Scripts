#!/bin/bash
source orange-cred.sh
DATE=$(date "+%Y-%m-%d")
MONTH=`date +"%d"`
WEEK=`date +"%u"`

echo "Backup des volumes DATA des instances Orange Cloudwatt"
echo "Lancement le $(date)"



for SERVER in 'Gitlab' 'Minio' 'Jira' 'VPN'
do
	#Etape 1 : Création du snapshot de l'instance
	echo "Etape 1/3 : Creation du snapshot du volume data de $SERVER"
	cinder snapshot-create $SERVER --force True --name Snap-$SERVER-$DATE

	if [ $? -ne 0 ]; then
	    echo "Echec lors de l'étape 1/3 : création du snapshot de $SERVER"
	    exit 2
	else
		echo "Creation du snapshot OK"
	fi

	#Etape 2 : Création d'un volume basé sur le snapshot de l'instance
	echo "Etape 2/3 : Creation du volume pour le backup de $SERVER"
	ID=$(openstack volume snapshot list | grep Snap-$SERVER-$DATE | sed 's/..//;s/.\{72\}$//')
	cinder create --snapshot-id $ID --display-name VolumeBak-$SERVER-$DATE

	if [ $? -ne 0 ]; then
	    echo "Echec lors de l'étape 2/3 : création du volume de $SERVER"
	    exit 2
	else
		echo "Creation du volume OK"
	fi

	#Etape 3 : Backup du volume crée
	echo "Etape 3/3 : Creation du backup de $SERVER"

	if [ ! -d  "/retention" ]; then
			mkdir /retention
	fi

	if [ "$MONTH" -eq 1 ]; then
		BACKUP=month
		touch  /retention/BackupMonthly-VolumeData-$SERVER-$DATE
  		cinder backup-create VolumeBak-$SERVER-$DATE --name BackupMonthly-VolumeData-$SERVER-$DATE
	elif [ "$WEEK" -eq 6 ]; then
		BACKUP=week
		touch  /retention/BackupWeekly-VolumeData-$SERVER-$DATE
    	cinder backup-create VolumeBak-$SERVER-$DATE --name BackupWeekly-VolumeData-$SERVER-$DATE
  	else
  		BACKUP=daily
  		touch  /retention/BackupDaily-VolumeData-$SERVER-$DATE
  		cinder backup-create VolumeBak-$SERVER-$DATE --name BackupDaily-VolumeData-$SERVER-$DATE
  	fi

	if [ $? -ne 0 ]; then
	    echo "Echec lors de l'étape 3/3 : création du volume de $SERVER"
	    exit 2
	else
		echo "Backup en cours de création : heure de démarrage $(date +"%T")"
        fi
	#Suppression du volume et du snapshot crée pour le backup
	STATE=$(openstack volume backup list | grep Backup-VolumeData-$SERVER-$DATE | sed 's/.\{71\}//;s/.\{9\}$//')
	while [ "$STATE" != "available"] 
	do
		sleep 300
		STATE=$(openstack volume backup list | grep Backup-VolumeData-$SERVER-$DATE | sed 's/.\{71\}//;s/.\{9\}$//')
	done

	echo "Backup terminé. Heure de fin $(date +"%T")"
	cinder snapshot-delete $ID
	cinder delete VolumeBak-$SERVER-$DATE

	#Gestion de la retention
	echo "Supression des anciennes sauvegardes"
	case $BACKUP in
		"monthly" ) SUPP=$(find /retention -name "BackupMonthly-*" -mtime +120 | sed 's/..//');;
		"weekly" ) SUPP=$(find /retention -name "BackupWeekly-*" -mtime +30 | sed 's/..//');;
		"daily" ) SUPP=$(find /retention -name "BackupDaily-*" -mtime +4  | sed 's/..//');;
	esac

	for i in $(echo $SUPP)
	do
	    cinder backup-delete $i
	    if [ $? -ne 0 ]; then
	    echo "Echec lors de la suppression du backup de $i"
	    exit 2
		else
			echo "Supression du backup de $i OK"
			find /retention -name $i -exec /bin/rm -vf {} \;
		fi
	done
done

echo "Sauvegardes des volumes des instances OK"
echo "Terminé le $(date)"
