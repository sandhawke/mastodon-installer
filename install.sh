#!/bin/sh

# Consider looking at https://www.npmjs.com/install.sh for how to make
# this script robust.  For now, restrict this to the tested OS.

OSVER=`lsb_release -ds`
SUP_OSVER='Debian GNU/Linux 8.8 (jessie)'
if [ "$OSVER" != "$SUP_OSVER" ]; then
    echo Sorry, written for $SUP_OSVER not $OSVER
    # exit 1
fi

ADMIN_EMAIL=sandro@hawke.org 
DOMAIN=`cat /etc/hostname`

echo "deb http://ftp.debian.org/debian/ jessie-backports main" \
     >> /etc/apt/sources.list.d/backports.list || exit 1
apt-get update || exit 1
time apt-get install -y -t jessie-backports ffmpeg libssl-dev || exit 1

# time apt-get install -y -t jessie-backports letsencrypt || exit 1
# time /usr/bin/letsencrypt certonly --email $ADMIN_EMAIL --agree-tos --standalone -d $DOMAIN || exit 1

time apt-get install -y -t jessie-backports nginx || exit 1

time apt-get install imagemagick libpq-dev libxml2-dev libxslt1-dev file git curl g++ libprotobuf-dev protobuf-compiler || exit 1
curl -sL https://deb.nodesource.com/setup_6.x | bash - || exit 1
time apt-get install nodejs || exit 1
time npm install -g yarn || exit 1

apt-get install redis-server redis-tools || exit 1

apt-get install postgresql postgresql-contrib || exit 1
postgresql-setup initdb || exit 1
systemctl start postgresql || exit 1
systemctl enable postgresql || exit 1
sudo -u postgres psql -c "CREATE USER mastodon CREATEDB;" || exit 1

adduser --disabled-password --gecos Mastodon mastodon || exit 1
sudo -u mastodon sh ./as_user.sh || exit 1

cp mastodon-*.service /etc/systemd/system  || exit 1
systemctl enable /etc/systemd/system/mastodon-*.service || exit 1
systemctl start mastodon-web.service mastodon-sidekiq.service mastodon-streaming.service || exit 1

sed s/example.com/$DOMAIN/ < nginx-config > /etc/nginx/sites-available/$DOMAIN || exit 1
ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/$DOMAIN || exit 1
service nginx start || exit 1