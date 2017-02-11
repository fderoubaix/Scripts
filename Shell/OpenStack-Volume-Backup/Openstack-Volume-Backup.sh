#!/bin/bash

DATE=$(date "+%d-%m-%Y")
MONTHLY=`date +"%d"`
WEEKLY=`date +"%u"`

if [ "$WEEKLY" -eq 7 ] &&  [ "$MONTHLY" -ne 1 ]; then
	echo "Dimanche : Pas de backup le $DATE  "
	exit 0
else
	echo "Backup des volumes DATA des instances Orange Cloudwatt"
	echo "Lancement le $(date)"

	source /home/frederic/Documents/orange-openrc.sh

	for SERVER in 'gitlab' 
	do
		#Etape 1 : Création du snapshot de l'instance
		echo "Etape 1/3 : Creation du snapshot du volume data de $SERVER"
		cinder snapshot-create "$SERVER"_data_volume --force True --name Snap-"$SERVER"-"$DATE"

		if [ $? -ne 0 ]; then
		    echo "Echec lors de l'étape 1/3 : création du snapshot de $SERVER"
		    exit 2
		else
			echo "Creation du snapshot OK"
		fi

		#Etape 2 : Création d'un volume basé sur le snapshot de l'instance
		echo "Etape 2/3 : Creation du volume pour le backup de $SERVER"
		ID=$(openstack volume snapshot list | grep Snap-"$SERVER"-"$DATE" | cut -d "|" -f 2 | cut -c 2-)
		cinder create --snapshot-id $ID --display-name VolumeBak-"$SERVER"-"$DATE"

		if [ $? -ne 0 ]; then
		    echo "Echec lors de l'étape 2/3 : création du volume de $SERVER"
		    echo "Revert : suppression du snapshot Snap-$SERVER-$DATE"
		    cinder snapshot-delete "$ID"
		    exit 2
		else
			echo "Creation du volume OK"
		fi

		#Etape 3 : Backup du volume crée
		echo "Etape 3/3 : Creation du backup de $SERVER"

		if [ ! -d  "/retention" ]; then
				mkdir /retention
		fi

		if [ "$MONTHLY" -eq 1 ]; then
			BACKUP=Monthly
			echo "Backup: Mensuel"
			touch  /retention/BackupMonthly-VolumeData-"$SERVER"-"$DATE"
	  		cinder backup-create VolumeBak-"$SERVER"-"$DATE" --name BackupMonthly-VolumeData-"$SERVER"-"$DATE"
		elif [ "$WEEKLY" -eq 6 ]; then
			BACKUP=Weekly
			echo "Backup: Hebdo"
			touch  /retention/BackupWeekly-VolumeData-"$SERVER"-"$DATE"
	    	cinder backup-create VolumeBak-"$SERVER"-"$DATE" --name BackupWeekly-VolumeData-"$SERVER"-"$DATE"
	  	else
	  		BACKUP=Daily
	  		echo "Backup: Journalier"
	  		touch  /retention/BackupDaily-VolumeData-"$SERVER"-"$DATE"
	  		cinder backup-create VolumeBak-"$SERVER"-"$DATE" --name BackupDaily-VolumeData-"$SERVER"-"$DATE"
	  	fi

		if [ $? -ne 0 ]; then
		    echo "Echec lors de l'étape 3/3 : création du volume de $SERVER"
		    echo "Revert : suppression du snapshot Snap-$SERVER-$DATE et du volume VolumeBak-$SERVER-$DATE"
		    cinder snapshot-delete "$ID"
		    cinder backup-delete VolumeBak-"$SERVER"-"$DATE"
		    exit 2
		else
			echo "Backup en cours de création : heure de démarrage $(date +"%T") ..."
		fi

		#Suppression du volume et du snapshot crée pour le backup
		STATE=$(openstack volume backup list | grep Backup"$BACKUP"-VolumeData-"$SERVER"-"$DATE" | cut -d "|" -f 5 | cut -c 2-)
		while [[ "$STATE" != "available" ]] 
		do
			sleep 300
			STATE=$(openstack volume backup list | grep Backup"$BACKUP"-VolumeData-"$SERVER"-"$DATE" | cut -d "|" -f 5 | cut -c 2-)
		done

		echo "Backup terminé. Heure de fin $(date +"%T")"
		cinder snapshot-delete "$ID"
		cinder delete VolumeBak-"$SERVER"-"$DATE"

		#Gestion de la retention
		echo "Recherche des anciennes sauvegardes à supprimer"
		case "$BACKUP" in
			"Monthly" ) SUPP=$(find /retention/BackupMonthly* -mtime +120 | cut -d "/" -f 3);;
			"Weekly" ) SUPP=$(find /retention/BackupWeekly* -mtime +30 | cut -d "/" -f 3);;
			"Daily" ) SUPP=$(find /retention/BackupDaily* -mtime +4  | cut -d "/" -f 3);;
		esac
		if [[ ! -z "$SUPP" ]]; then
			for i in $(echo "$SUPP")
			do
			    echo "Suppression du backup : $i ..."
			    cinder backup-delete "$i"
			    if [ $? -ne 0 ]; then
				    echo "Echec lors de la suppression du backup de $i"
				    exit 2
			    else
					echo "Supression du backup de $i OK"
					find /retention -name "$i" -exec /bin/rm -vf {} \;
			    fi
			done
		else
			echo "Pas de suppression à effectuer"
		fi
	done

	echo "Sauvegardes des volumes des instances OK"
	echo "Terminé le $(date)"
fi
exit 0
