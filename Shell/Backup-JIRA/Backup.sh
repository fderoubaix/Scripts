echo === Backup BBD JIRA du $(date "+%d-%m-%Y") ===


Mysql_User="jiradbuser"
Mysql_Paswd=""

mysqldump -u $Mysql_User -p$Mysql_Paswd jiradb | gzip -9 > /usr/local/web/atlassian/jira/backup/db-jira-$(date +"%d-%m-%Y").gz

if [ $? -ne 0 ]; then
    echo "Backup: echec du backup de la BDD"
    exit 2
else
    echo === Supp des backup de plus de 7 jours ===
    find /usr/local/web/atlassian/jira/backup/*.gz -mtime +7 -exec /bin/rm -vf {} \;
    echo "=== Backup de Gitlab du $(date "+%d-%m-%Y") OK ==="
fi

