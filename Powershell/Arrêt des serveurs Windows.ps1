#By F.Deroubaix
#Ce script permet l'arr�t des serveurs Windows pr�sent dans le fichier "Server.txt" (fichier disponible sur le serveur XXXX)
#Un enregistrement de log est ensuite disponible pour v�rifier les arr�ts : Arret-serveurs-"date".txt dans le dossier logs\PowerShell


$wshell = New-Object -ComObject Wscript.Shell
$a=$wshell.Popup("Attention, vous �tes sur le point de lancer le script d'arr�t des serveurs ! Souhaitez-vous r�ellement �teindre les serveurs Telma ?",0,"Arr�t serveurs Telma ?",0x21)
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
    write-host "Op�ration d'extinction des serveurs Windows de TELMA termin�e
    Un fichier r�sumant l'op�ration est diponible : E:\Logs\PowerShell\Arret-serveurs.txt" -ForegroundColor "Yellow"
    Stop-Transcript
    read-host "Appuyez sur une touche pour quitter"  
    
    }