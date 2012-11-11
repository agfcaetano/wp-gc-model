#!/bin/sh
function plugin_install(){
  cd /tmp
  /usr/bin/wget http://downloads.wordpress.org/plugin/$1
  /usr/bin/unzip /tmp/$1 -d /var/www/vhosts/$2/wp-content/plugins/
  /bin/rm /tmp/$1
}

SERVERNAME=$1
INSTANCEID=default
TZ="Asia\/Tokyo"

cd /tmp/

if [ "$SERVERNAME" = "$INSTANCEID" ]; then
  /bin/mv /etc/localtime /etc/localtime.bak
  /bin/cp -p /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
  /bin/cp /tmp/wp-gc-model/etc/motd.jp /etc/motd
  /bin/cp /tmp/wp-gc-model/etc/sysconfig/i18n.jp /etc/sysconfig/i18n
fi
  
/bin/cp -Rf /tmp/wp-gc-model/etc/nginx/* /etc/nginx/
sed -e "s/\$host\([;\.]\)/$INSTANCEID\1/" /tmp/wp-gc-model/etc/nginx/conf.d/default.conf > /etc/nginx/conf.d/default.conf
sed -e "s/\$host\([;\.]\)/$INSTANCEID\1/" /tmp/wp-gc-model/etc/nginx/conf.d/default.backend.conf > /etc/nginx/conf.d/default.backend.conf
if [ "$SERVERNAME" = "$INSTANCEID" ]; then
  /sbin/service nginx stop
  /bin/rm -Rf /var/log/nginx/*
  /bin/rm -Rf /var/cache/nginx/*
  /sbin/service nginx start
else
  sed -e "s/\$host\([;\.]\)/$SERVERNAME\1/" /tmp/wp-gc-model/etc/nginx/conf.d/default.conf | sed -e "s/ default;/;/" | sed -e "s/\(server_name \)_/\1$SERVERNAME/" | sed -e "s/\(\\s*\)\(include     \/etc\/nginx\/phpmyadmin;\)/\1#\2/" > /etc/nginx/conf.d/$SERVERNAME.conf
  sed -e "s/\$host\([;\.]\)/$SERVERNAME\1/" /tmp/wp-gc-model/etc/nginx/conf.d/default.backend.conf | sed -e "s/ default;/;/" | sed -e "s/\(server_name \)_/\1$SERVERNAME/" > /etc/nginx/conf.d/$SERVERNAME.backend.conf
  /usr/sbin/nginx -s reload
fi

if [ "$SERVERNAME" = "$INSTANCEID" ]; then
  /sbin/service php-fpm stop
  sed -e "s/date\.timezone = \"UTC\"/date\.timezone = \"$TZ\"/" /tmp/wp-gc-model/etc/php.ini > /etc/php.ini
  /bin/cp -Rf /tmp/wp-gc-model/etc/php.d/* /etc/php.d/
  /bin/cp /tmp/wp-gc-model/etc/php-fpm.conf /etc/
  /bin/cp -Rf /tmp/wp-gc-model/etc/php-fpm.d/* /etc/php-fpm.d/
  /bin/rm -Rf /var/log/php-fpm/*
  /sbin/service php-fpm start
fi

if [ "$SERVERNAME" = "$INSTANCEID" ]; then
  /sbin/service mysql stop
  /bin/cp /tmp/wp-gc-model/etc/my.cnf /etc/
  /bin/rm /var/lib/mysql/ib_logfile*
  /bin/rm /var/log/mysqld.log*
  /sbin/service mysql start
fi

echo "WordPress install ..."
/usr/bin/wget http://ja.wordpress.org/latest-ja.tar.gz > /dev/null 2>&1
/bin/tar xvfz /tmp/latest-ja.tar.gz > /dev/null 2>&1
/bin/rm /tmp/latest-ja.tar.gz
/bin/mv /tmp/wordpress /var/www/vhosts/$SERVERNAME
plugin_install "nginx-champuru.1.1.5.zip" "$SERVERNAME" > /dev/null 2>&1
plugin_install "head-cleaner.1.4.2.10.zip" "$SERVERNAME" > /dev/null 2>&1
plugin_install "wp-total-hacks.1.0.2.zip" "$SERVERNAME" > /dev/null 2>&1
plugin_install "jetpack.2.0.zip" "$SERVERNAME" > /dev/null 2>&1
plugin_install "worker.zip" "$SERVERNAME" > /dev/null 2>&1
plugin_install "w3-total-cache.0.9.2.4.zip" "$SERVERNAME" > /dev/null 2>&1
plugin_install "wp-optimize.0.9.4.zip" "$SERVERNAME" > /dev/null 2>&1
plugin_install "login-lockdown.1.5.zip" "$SERVERNAME" > /dev/null 2>&1
if [ -f /tmp/wp-gc-model/wp-setup.php ]; then
  /usr/bin/php /tmp/wp-gc-model/other/wp-setup.php $SERVERNAME $INSTANCEID
fi
echo "... WordPress installed"

/bin/chown -R nginx:nginx /var/log/nginx
/bin/chown -R nginx:nginx /var/log/php-fpm
/bin/chown -R nginx:nginx /var/cache/nginx
/bin/chown -R nginx:nginx /var/tmp/php
/bin/chown -R nginx:nginx /var/www/vhosts/$SERVERNAME
