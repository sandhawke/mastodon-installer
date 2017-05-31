#!/bin/sh

set -x
cd

if [ ! -e "./.rbenv/plugins/ruby-build/share/ruby-build/2.4.1" ]; then
    echo correct version of ruby: not found
    rm -rf ~/.rbenv
    time git clone https://github.com/rbenv/rbenv.git ~/.rbenv || exit 1
    echo 'PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(rbenv init -)"' >> ~/.bashrc
    
    echo HOME is $HOME
    PATH="$HOME/.rbenv/bin:$PATH"
    echo PATH is $PATH
    eval "$(rbenv init -)"

    rm -rf ~/.rbenv/plugins/ruby-build
    time git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build || exit 1
    time rbenv install 2.4.1 || exit 1
else
    echo ruby is good
fi

mv live old.live.`date +%Y-%m-%d-%H%M%S`
git clone https://github.com/tootsuite/mastodon.git live
cd live

VERSION=`cat ~/mastodon_version.txt`
if [ -z "$VERSION" ]; then
    VERSION=`git tag | tail -n 1`
fi
git checkout $VERSION || exit 1 
#  you are in detached head

time gem install bundler || exit 1
#  18s titanic
#  11s mega
#  19s box94

### time bundle install --deployment --without development test || exit 1
time bundle install --deployment || exit 1
#  8m on titanic + error!
#  10m box94 10m and: Failed to locate protobuf
#  6:14 on mega 

#  mega  5m55 1.3
#  b94  9m23 1.3

time yarn install || exit 1
# 3m

DOMAIN=`cat /etc/hostname`
cp .env.production.sample .env.production
sed -i s/^REDIS_HOST=.*/REDIS_HOST=localhost/ .env.production
sed -i 's;^DB_HOST=.*;DB_HOST=/var/run/postgresql;' .env.production
sed -i 's;^DB_USER=.*;DB_USER=mastodon;' .env.production
sed -i 's;^DB_NAME=.*;DB_NAME=mastodon_production;' .env.production
sed -i s/^LOCAL_DOMAIN=.*/LOCAL_DOMAIN=$DOMAIN/ .env.production
SECRET=`bundle exec rake secret`;sed -i s/^PAPERCLIP_SECRET=.*/PAPERCLIP_SECRET=$SECRET/ .env.production
SECRET=`bundle exec rake secret`;sed -i s/^OTP_SECRET=.*/OTP_SECRET=$SECRET/ .env.production
SECRET=`bundle exec rake secret`;sed -i s/^SECRET_KEY_BASE=.*/SECRET_KEY_BASE=$SECRET/ .env.production
sed -i s/^DEFAULT_LOCALE=.*/DEFAULT_LOCALE=en/ .env.production

sed -i s/^SMTP_LOGIN=.*/SMTP_LOGIN=notifications@$DOMAIN/ .env.production

# from https://app.mailgun.com/app/domains/$DOMAIN/credentials
# for notifications acct.   COULD use a different domain, maybe.
SMTPPASSWORD=`cat ~/smtp_password.txt`
if [ ! -z "$SMTPPASSWORD" ]; then
    sed -i s/^SMTP_FROM_ADDRESS=.*/SMTP_FROM_ADDRESS=notifications@$DOMAIN/ .env.production
    sed -i s/^SMTP_PASSWORD=.*/SMTP_PASSWORD=$SMTPPASSWORD/ .env.production
fi

export RAILS_ENV=production
time bundle exec rails db:setup || exit 1
time bundle exec rails assets:precompile || exit 1

echo '0 0 * * * RAILS_ENV=production cd /home/mastodon/live && /home/mastodon/.rbenv/shims/bundle exec rake mastodon:daily > /dev/null' | crontab && crontab -l

echo as_user.sh complete
