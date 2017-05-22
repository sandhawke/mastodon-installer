#!/bin/sh

# SMTPPASSWORD=`cat /root/.mastodon_smtp_password` || exit 1

cd

time git clone https://github.com/rbenv/rbenv.git ~/.rbenv || exit 1
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
. ~/.bash_profile || exit 1

time git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build || exit 1
time rbenv install 2.4.1 || exit 1

git clone https://github.com/tootsuite/mastodon.git live
cd live
# git checkout $(git tag | tail -n 1)
git checkout v1.3.3
#  you are in detached head

time gem install bundler
#  18s titanic
#  11s mega
#  19s box94

time bundle install --deployment --without development test
#  8m on titanic + error!
#  10m box94 10m and: Failed to locate protobuf
#  6:14 on mega 

#  mega  5m55 1.3
#  b94  9m23 1.3

time yarn install
# 3m

DOMAIN=`cat /etc/hostname`
cp .env.production.sample .env.production
sed -i s/^REDIS_HOST=.*/REDIS_HOST=localhost/ .env.production
sed -i 's;^DB_HOST=.*;DB_HOST=/var/run/postgresql;' .env.production
sed -i 's;^DB_USER=.*;DB_USER=mastodon;' .env.production
sed -i 's;^DB_NAME=.*;DB_NAME=mastodon_production;' .env.production
sed -i s/^LOCAL_DOMAIN=.*/LOCAL_DOMAIN=$DOMAIN/ .env.production
SECRET=`rake secret`;sed -i s/^PAPERCLIP_SECRET=.*/PAPERCLIP_SECRET=$SECRET/ .env.production
SECRET=`rake secret`;sed -i s/^OTP_SECRET=.*/OTP_SECRET=$SECRET/ .env.production
SECRET=`rake secret`;sed -i s/^SECRET_KEY_BASE=.*/SECRET_KEY_BASE=$SECRET/ .env.production
sed -i s/^DEFAULT_LOCALE=.*/DEFAULT_LOCALE=en/ .env.production

sed -i s/^SMTP_LOGIN=.*/SMTP_LOGIN=notifications@$DOMAIN/ .env.production

#sed -i s/^SMTP_FROM_ADDRESS=.*/SMTP_FROM_ADDRESS=notifications@$DOMAIN/ .env.production
#sed -i s/^SMTP_PASSWORD=.*/SMTP_PASSWORD=$SMTPPASSWORD/ .env.production

# add #SMTPPASSWORD
#firefox https://app.mailgun.com/app/domains/$DOMAIN/credentials

RAILS_ENV=production time bundle exec rails db:setup
RAILS_ENV=production time bundle exec rails assets:precompile

echo '0 0 * * * RAILS_ENV=production cd /home/mastodon/live && /home/mastodon/.rbenv/shims/bundle exec rake mastodon:daily > /dev/null' | crontab && crontab -l

