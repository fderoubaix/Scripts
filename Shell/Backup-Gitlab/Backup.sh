echo === Backup du $(date "+%d-%m-%Y") ===
echo === Backup DB Gitlab ===
gitlab-rake gitlab:backup:create
cp -vu /var/opt/gitlab/backups/*  /usr/local/web/gitlab/backup/db/

if [ $? -ne 0 ]; then
    echo "Backup: echec du backup DB"
    exit 2
fi

echo === Backup Conf Gitlab ===
tar czfv /usr/local/web/gitlab/backup/conf/conf-$(date "+%Y-%m-%d").tgz /etc/gitlab

if [ $? -ne 0 ]; then
    echo "Backup: echec du backup de la Conf"
    exit 2
else
    find /usr/local/web/gitlab/backup/conf/*.tgz -mtime +7 -exec /bin/rm -f {} \;
    find /usr/local/web/gitlab/backup/db/*.tar -mtime +7 -exec /bin/rm -f {} \;
    echo "=== Backup de Gitlab du $(date "+%d-%m-%Y") OK ==="
fi

