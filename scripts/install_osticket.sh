#!/bin/bash

set -e

echo "Actualizando sistema y habilitando repositorios..."
sudo apt update
sudo apt install -y software-properties-common unzip wget
sudo add-apt-repository -y universe
sudo add-apt-repository -y multiverse
sudo apt update

echo "Instalando Apache, MySQL y PHP..."
sudo apt install -y apache2 mysql-server php php-cli php-mysql php-imap php-gd \
php-intl php-mbstring php-xml php-curl php-apcu

echo "Creando base de datos y usuario MySQL..."
sudo mysql -u root <<EOF
CREATE DATABASE osticket;
CREATE USER 'osticketuser'@'localhost' IDENTIFIED BY 'Osticketpass123.';
ALTER USER 'osticketuser'@'localhost' IDENTIFIED BY 'Osticketpass123.';
GRANT ALL PRIVILEGES ON osticket.* TO 'osticketuser'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "Descargando osTicket..."
cd /tmp
wget https://github.com/osTicket/osTicket/releases/download/v1.18.1/osTicket-v1.18.1.zip
unzip osTicket-v1.18.1.zip
sudo mv upload /var/www/html/osticket

echo "Asignando permisos..."
sudo chown -R www-data:www-data /var/www/html/osticket

echo "Configurando sitio en Apache..."
sudo tee /etc/apache2/sites-available/osticket.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerAdmin admin@localhost
    DocumentRoot /var/www/html/osticket
    <Directory "/var/www/html/osticket">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

echo "Habilitando sitio y módulos..."
sudo a2ensite osticket.conf
sudo a2dissite 000-default.conf
sudo a2enmod rewrite
sudo systemctl restart apache2

echo "Cambiando nombre de archivo os-sampleconfig.php a os-config.php"
sudo mv /var/www/html/osticket/include/ost-sampleconfig.php /var/www/html/osticket/include/ost-config.php

echo "Configurando el firewall para permitir tráfico HTTP y HTTPS..."
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

echo "Instalación completada. Versión de PHP:"
php -v

echo "Accede a http://<IP-del-servidor> para finalizar la instalación web."
