#! /bin/sh

#Dependances a installer : bluethoot / bluez
#Utiliser la commande "lspci" pour avoir des infos sur le matériel si le bluetooth est sur le bus PCI
#Utiliser "lsusb" pour une cle usb bluetooth, puis "usb-devices"
#Utiliser "hcitool scan" pour scanner les peripheriques bluetooth a proximite

TELEPHONE=84:CF:BF:88:8A:C4 #@ Mac du telephone, trouve avec hcitool scan
NOMTEL=FP2 #Nom personnel du téléphone

VERROU=NON # Indique si l'écran est vérouillé. Au début, l'écran n'est pas vérouillé, donc le verrou sur "non"

while sleep 12 ; do
	NOM=`hcitool name $TELEPHONE` #Si le telephone est présent, il va répondre son nom
	echo nom: $NOM
	if [ "x$NOM" = "x$NOMTEL" ]; #Le "x" permet d'eviter une erreur syntaxe si variable NOM est vide
	then
		if [ $VERROU = OUI ];
		then
			echo deverouille
			kill $LOCKPID
					
		fi
			VERROU=NON
		
	else
		if [ $VERROU = NON ];
		then
			echo verouille
			xtrlock -b & #Verouille l'ecran en mode "blank"
				LOCKPID=$! #Stock le PID qu'il faudra KILL pour deverouiller
		fi
	VERROU=OUI
	fi
done
