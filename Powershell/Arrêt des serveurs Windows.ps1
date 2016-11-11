#By F.Deroubaix
#Ce script permet l'arrêt des serveurs Windows présent dans le fichier "Server.txt" (fichier disponible sur le serveur XXXX)
#Un enregistrement de log est ensuite disponible pour vérifier les arrêts : Arret-serveurs-"date".txt dans le dossier logs\PowerShell


$wshell = New-Object -ComObject Wscript.Shell
$a=$wshell.Popup("Attention, vous êtes sur le point de lancer le script d'arrêt des serveurs ! Souhaitez-vous réellement éteindre les serveurs Telma ?",0,"Arrêt serveurs Telma ?",0x21)
if ($a -eq 2){
    exit 
    }
elseif ($a -eq 1) {
    $date = (Get-Date).ToString('dd-MM-yyyy')
    Start-Transcript E:\Logs\PowerShell\Arret-serveurs-$date.txt
    Get-content "\\XXXX\services\informatique\Scripts\Arret Serveurs\Servers.txt" |
    where {test-connection $_ -quiet -count 2} |
    foreach {
        Write-Host "Arret du serveur $_ " -ForegroundColor "Green" 
        Stop-Computer $_ -force }
    write-host "Opération d'extinction des serveurs Windows de TELMA terminée
    Un fichier résumant l'opération est diponible : E:\Logs\PowerShell\Arret-serveurs.txt" -ForegroundColor "Yellow"
    Stop-Transcript
    read-host "Appuyez sur une touche pour quitter"  
    
    }