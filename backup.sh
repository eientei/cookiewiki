#!/bin/sh

function unlock() {
  docker exec -ti $(docker ps -f label=org.cookie.container=mediawiki --format='{{.ID}}') \
    sh -c "sed '/wgReadOnly/d' -i LocalSettings.php"
}

trap unlock EXIT

docker exec -ti $(docker ps -f label=org.cookie.container=mediawiki --format='{{.ID}}') \
  sh -c "echo '\$wgReadOnly = \"Dumping Database, Access will be restored shortly\";' >> LocalSettings.php"

now=$(date +%F-%H-%M-%S)

mkdir -p temp

docker exec -ti $(docker ps -f label=org.cookie.container=mariadb --format='{{.ID}}') \
  mysqldump -ppassword mediawiki | gzip -9 > temp/database.sql.gz

tar --transform "s/data\/web/$now\/web/;s/temp/$now\/sql/" -czvf backups/${now}.tar.gz temp/database.sql.gz data/web

rm -r temp

# remove every backup but
# - each per day of last month
# - each per month of last year
# - each per year
find backups/ -type f -name '*.tar.gz' | sort -n | awk -F '[-./]' '
BEGIN{
  year=month=day=0;
}
{ 
  if (!year) {
    year=$2;
    month=$3;
    day=$4;
    keep[year][month][day]=lastday=$0;
    next
  }
  if (year == $2 && month == $3 && day == $4) { 
    print lastday;
  }
  if (year != $2) {
    for (m in keep[year]) {
      for (d in keep[year][m]) {
        if (m == month && d == day) { 
          continue
        }
        print keep[year][m][d]
      }
    }
    delete keep[year];
    keep[year][month][day]=lastday;
    year=$2;
    month=$3
  }
  if (month != $3) {
    for (d in keep[year][month]) {
      if (d == day) {
        continue
      }
      print keep[year][month][d]
    }
    delete keep[year][month];
    keep[year][month][day]=lastday;
    month=$3;
  }
  day=$4;
  keep[year][month][day]=$0;
  lastday=$0;
}' | xargs rm -vf
