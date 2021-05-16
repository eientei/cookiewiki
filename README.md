CookieWiki☆ docker-compose environment
===

Based on https://github.com/ubc/mediawiki-docker/tree/REL1_35


Setup
===

1. Clone repository
2. Adjust docker-compose.yml to match your external domains (`MEDIAWIKI_SITE_SERVER`, `PARSOID_DOMAIN`) and port (8086)
3. `docker-compose up -d`
4. Setup a reverse proxy from your SSL-terminating http server to local wiki port (8086)

Backup
===

Create a webdata+sql backup, rotate older backups to keep 1 per day of last month, 1 per month of last year and 1 per year

```
./backup.sh

```

Restore
===

```
cp -aR backups/2021-05-16-17-36-31/web/* data/web/
chown -R 33 data/web/images/
cat backups/2021-05-16-17-36-31/sql/database.sql.gz | gzip -d |  docker exec -i $(docker ps -f label=org.cookie.container=mariadb --format='{{.ID}}') mysql -ppassword mediawiki
```
