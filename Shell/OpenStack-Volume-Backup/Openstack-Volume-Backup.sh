#!/bin/bash
# Février 2017, By Frédéric Deroubaix
#Script de sauvegarde des volumes "data" des instances Openstack
#Le SDK Python pour Openstack doit être installés !


#Définir ici la politique de rétention souhaitée (en jours) pour la conservation des backup Daily, Weekly et Monthly.
#La rétention débute à 48h (2 jours) avec la valeur "1" (exemple: pour 4 jours de rétentions, mettre la valeur "3" dans RDAILY)
RDAILY=3
RWEEKLY=2
RMONTHLY=2
##
#Définir ici le fichier contenant les variables d'environnement pour la connexion sur l'environnement Openstack
VARAUTH=/home/frederic/Documents/orange-openrc.sh
##

DATE=$(date "+%d-%m-%Y")
MONTHLY=`date +"%d"`
WEEKLY=`date +"%u"`

if [ "$WEEKLY" -eq 7 ] && [ "$MONTHLY" -ne 1 ]; then
	echo "=== === === === === === === === === === === === === === ==="
	echo "*** Dimanche : Pas de backup le $DATE *** "
	echo "=== === === === === === === === === === === === === === ==="
	exit 0
else
	source "$VARAUTH"

	if [ "$MONTHLY" -eq 1 ]; then
		BACKUP=Monthly
	elif [ "$WEEKLY" -eq 6 ]; then
		BACKUP=Weekly
	else
	  	BACKUP=Daily
	fi

	echo "=== === === === === === === === === === === === === === ==="
	echo "*** Backup des volumes DATA des instances Orange Cloudwatt ***"
	echo "*** Date d'execution du backup: $(date) ***"
	echo "*** Lancement du backup en mode: $BACKUP ***"
	echo "=== === === === === === === === === === === === === === ==="

	for SERVER in 'vpn' 'gitlab' 'jira' 'minio'
	do
		#Etape 1 : Création du snapshot de l'instance
		echo "*** Etape 1/3 : Creation du snapshot du volume data de $SERVER ***"
		VOLNAME=$(cinder list | grep "$SERVER" | cut -d "|" -f 4 | cut -c 2- | tr -d ' ')
		cinder snapshot-create "$VOLNAME" --force True --name Snap-"$SERVER"-"$DATE"

		if [ $? -ne 0 ]; then
		    echo "Echec lors de l'étape 1/3 : création du snapshot de $SERVER"
		    echo "Echec lors de l'étape 1/3 : création du snapshot de $SERVER" > /var/log/backup_result
		    exit 2
		else
			echo "Creation du snapshot OK"
		fi

		#Etape 2 : Création d'un volume basé sur le snapshot de l'instance
		echo "*** Etape 2/3 : Creation du volume pour le backup de $SERVER ***"
		ID=$(openstack volume snapshot list | grep Snap-"$SERVER"-"$DATE" | cut -d "|" -f 2 | cut -c 2- | tr -d ' ')
		cinder create --snapshot-id $ID --display-name VolumeBak-"$SERVER"-"$DATE"

		if [ $? -ne 0 ]; then
		    echo "Echec lors de l'étape 2/3 : création du volume de $SERVER"
		    echo "Echec lors de l'étape 2/3 : création du volume de $SERVER" > /var/log/backup_result
		    echo "Revert : suppression du snapshot Snap-$SERVER-$DATE"
		    cinder snapshot-delete "$ID"
		    exit 2
		else
			echo "Creation du volume OK"
		fi

		#Etape 3 : Backup du volume crée
		echo "*** Etape 3/3 : Creation du backup de $SERVER ***"

		if [ ! -d  "/retention" ]; then
				mkdir /retention
		fi

		if [ "$BACKUP" -eq Monthly ]; then
			touch  /retention/BackupMonthly-VolumeData-"$SERVER"-"$DATE"
	  		cinder backup-create VolumeBak-"$SERVER"-"$DATE" --name BackupMonthly-VolumeData-"$SERVER"-"$DATE"
		elif [ "$BACKUP" -eq Weekly ]; then
			touch  /retention/BackupWeekly-VolumeData-"$SERVER"-"$DATE"
	    	cinder backup-create VolumeBak-"$SERVER"-"$DATE" --name BackupWeekly-VolumeData-"$SERVER"-"$DATE"
	  	else
	  		touch  /retention/BackupDaily-VolumeData-"$SERVER"-"$DATE"
	  		cinder backup-create VolumeBak-"$SERVER"-"$DATE" --name BackupDaily-VolumeData-"$SERVER"-"$DATE"
	  	fi

		if [ $? -ne 0 ]; then
		    echo "Echec lors de l'étape 3/3 : création du volume de $SERVER"
		    echo "Echec lors de l'étape 3/3 : création du volume de $SERVER" > /var/log/backup_result
		    echo "Revert : suppression du snapshot Snap-$SERVER-$DATE et du volume VolumeBak-$SERVER-$DATE"
		    cinder snapshot-delete "$ID"
		    cinder backup-delete VolumeBak-"$SERVER"-"$DATE"
		    rm -vf /retention/BackupMonthly-VolumeData-"$SERVER"-"$DATE"
		    exit 2
		else
			echo "Backup pour le serveur $SERVER en cours de création : heure de démarrage $(date +"%T") ..."
		fi

		# Etape 4 : Suppression du volume et du snapshot crée pour le backup
		STATE=$(openstack volume backup list | grep Backup"$BACKUP"-VolumeData-"$SERVER"-"$DATE" | cut -d "|" -f 5 | cut -c 2- | tr -d ' ')
		while [[ "$STATE" != available ]] 
		do
			sleep 30
			STATE=$(openstack volume backup list | grep Backup"$BACKUP"-VolumeData-"$SERVER"-"$DATE" | cut -d "|" -f 5 | cut -c 2- | tr -d ' ')
		done

		echo "Backup $SERVER terminé. Heure de fin $(date +"%T")"
		cinder snapshot-delete "$ID"
		cinder delete VolumeBak-"$SERVER"-"$DATE"
	done

	#Gestion de la retention
	echo "*** Recherche des anciennes sauvegardes $BACKUP à supprimer ... ***"
	case "$BACKUP" in
		"Monthly" ) SUPP=$(find /retention/BackupMonthly* -mtime "$RMONTHLY" | cut -d "/" -f 3);;
		"Weekly" ) SUPP=$(find /retention/BackupWeekly* -mtime "$RWEEKLY" | cut -d "/" -f 3);;
		"Daily" ) SUPP=$(find /retention/BackupDaily* -mtime "$RDAILY" | cut -d "/" -f 3);;
	esac
	if [[ ! -z "$SUPP" ]]; then
		for i in $(echo "$SUPP")
		do
			echo "Suppression du backup : $i ..."
			cinder backup-delete "$i"
			if [ $? -ne 0 ]; then
			    echo "Echec lors de la suppression du backup de $i"
			    echo "Backup OK mais echec lors de la suppression de l'ancien backup $i" > /var/log/backup_result
		    else
				find /retention -name "$i" -exec /bin/rm -vf {} \;
				echo "Supression du backup de $i : OK"
		    fi
		done
	else
		echo "OK Pas de suppression à effectuer"
	fi
echo "=== === === === === === === === === === === === === === ==="
echo "*** Script de backup terminé avec succès le $(date) ***"
echo "Etat du backup le $(date) : SUCCES" > /var/log/backup_result
echo "=== === === === === === === === === === === === === === ==="
exit 0
fi

