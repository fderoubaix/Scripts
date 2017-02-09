echo === Backup BBD Pritunl du $(date "+%d-%m-%Y") ===

mongodump --out /usr/local/web/pritunl/backup/$(date +"%d-%m-%Y")/

if [ $? -ne 0 ]; then
    echo "Backup: echec du backup de la BDD"
    exit 2
else
    echo === Supp des backup de plus de 7 jours ===
    find /usr/local/web/pritunl/backup/* -mtime +7 -exec /bin/rm -vrf {} \;
    echo "=== Backup de Pritunl du $(date "+%d-%m-%Y") OK ==="
fi

