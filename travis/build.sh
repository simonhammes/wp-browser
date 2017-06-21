#!/usr/bin/env bash

wpFolder=/tmp/wordpress
wpDbName=test
wpLoaderDbName=wploader
wpDbPrefix=wp_
wpUrl=wordpress.dev
wpAdminUsername=admin
wpAdminPassword=admin
wpSubdomain1=test1
wpSubdomain1Title="Test Subdomain 1"
wpSubdomain2=test2
wpSubdomain2Title="Test Subdomain 2"

wpVersion=latest
# wpVersion=nightly

mysql -e "create database IF NOT EXISTS $wpDbName;" -uroot
mysql -e "create database IF NOT EXISTS $wpLoaderDbName;" -uroot

composer update --prefer-dist

# set up folders
mkdir -p $HOME/tools /tmp/wordpress

# install wp-cli
wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -P /tmp/tools/
chmod +x /tmp/tools/wp-cli.phar && mv /tmp/tools/wp-cli.phar /tmp/tools/wp
export PATH=$PATH:/tmp/tools:vendor/bin

# install Apache and WordPress setup scripts
git clone https://github.com/lucatume/travis-apache-setup.git /tmp/tools/travis-apache-setup
chmod +x /tmp/tools/travis-apache-setup/apache-setup.sh
chmod +x /tmp/tools/travis-apache-setup/wp-install.sh
ln -s /tmp/tools/travis-apache-setup/apache-setup.sh /tmp/tools/apache-setup
ln -s /tmp/tools/travis-apache-setup/wp-install.sh /tmp/tools/wp-install

# download and install WordPress
wp-install \
  --version="$wpVersion" \
  --dir=/tmp/wordpress \
  --dbname="$wpDbName" \
  --dbuser="root" \
  --dbpass="" \
  --dbprefix=wp_ \
  --domain="wordpress.dev" \
  --title="Test" \
  --base=/ \
  --admin_user=admin \
  --admin_password=admin \
  --admin_email=admin@wordpress.dev \
  --theme=twentysixteen \
  --multisite \
  --subdomains

cd /tmp/wordpress
wp site create --slug=$wpSubdomain1 --title="$wpSubdomain1Title"
wp site create --slug=$wpSubdomain2 --title="$wpSubdomain2Title"

# flush rewrite rules
wp rewrite structure '/%postname%/'

# export a dump of the just installed database to the _data folder
cd /tmp/wordpress
wp db export $TRAVIS_BUILD_DIR/tests/_data/dump.sql

# set up Apache virtual host
sudo env "PATH=$PATH" apache-setup \
    --host="127.0.0.1" \
    --url="$wpUrl" --dir="/tmp/wordpress"

# set the path to the phantomjs bin in Phantoman
sed -i "s_phantomjsbin_$(which phantomjs)_" $TRAVIS_BUILD_DIR/codeception.dist.yml

# Get back to Travis build dir
cd $TRAVIS_BUILD_DIR
