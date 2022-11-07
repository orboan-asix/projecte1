#!/bin/bash

# apache2 conf files
\cp -r /resources/etc/apache2/sites-available/*.conf /etc/apache2/sites-available/
cd /etc/apache2/sites-available
cuser=$(ls /home)
chmod 755 /home/$cuser
mkdir -p /home/$cuser/www/html
if [ ! -f "/home/$cuser/www/html/index.html" ]; then
    echo "<html><h1>Projecte 1: $cuser says hello!</h1></html>" > /home/$cuser/www/html/index.html
fi
chown 1000:100 -R /home/$cuser/www
sed -i "s|DocumentRoot /var/www/html|DocumentRoot /home/$cuser/www/html|g" 000-default.conf
sed -i "s|DocumentRoot /var/www/html|DocumentRoot /home/$cuser/www/html|g" default-ssl.conf
cd /etc/apache2/sites-enabled
ln -s ../sites-available/default-ssl.conf .
cd ..
sed -i "s|AllowOverride None|AllowOverride All|g" apache2.conf
sed -i "s|/var/www/|/home/$cuser/www/|g" apache2.conf
echo "ServerName 127.0.0.1" >> apache2.conf

exit 0
