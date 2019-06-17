######################
# Don't remove this :P
echo "Doing apt-get update"

apt-get update

######################
# Install Apache & PHP
echo "Installing Apache & PHP"

apt-get install -y apache2
apt-get install -y php

###############
# Install MySQL
echo "Installing MySQL"

debconf-set-selections <<< "mysql-server mysql-server/root_password password root"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password root"
apt-get -y install mysql-server

#####################
# Install PHP modules
echo "Installing PHP Modules"

# apt-get install -y php-pear php-fpm php-dev php-zip php-curl php-xmlrpc php-gd php-mysql php-mbstring php-xml libapache2-mod-php

####################
# Enable mod rewrite
echo "Enabling mod rewrite"

a2enmod rewrite

# We need AllowOverride all too...
cat > /etc/apache2/sites-available/000-default.conf << EOL
<VirtualHost *:80>
	ServerAdmin webmaster@localhost
	DocumentRoot /var/www/html

	<Directory /var/www/html>
		AllowOverride all
	</Directory>

	ErrorLog \${APACHE_LOG_DIR}/error.log
	CustomLog \${APACHE_LOG_DIR}/access.log combined
</Virtualhost>
EOL

# Restart apache
echo "Restarting Apache"

systemctl restart apache2

##################
# Symlink /var/www
if ! [ -L /var/www/html ]; then
	echo "Creating var/www symlink to vagrant dir"

	rm -rf /var/www/html
	ln -fs /vagrant /var/www/html
fi

##########################
# Install curl & git & nfs
echo "Installing cURL & GIT"

apt-get install -y curl
apt-get install -y git
apt-get install -y nfs-common portmap

##############
# Install node
echo "Installing Node"

curl -sL https://deb.nodesource.com/setup_11.x | sudo -E bash -
apt-get install -y nodejs

##############
# Install gulp
echo "Installing Gulp"

npm install --global gulp-cli

#######################
# Install WordPress CLI
echo "Installing WP CLI"

curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp
