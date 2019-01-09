THEMENAME=$1
SITENAME="${THEMENAME^}"
DBNAME="wp_$THEMENAME"
DBPREFIX="wp_"
SITEURL=$2

###########
# Setup GIT
if ! [ -d /vagrant/.git ]; then
	echo "Initializing GIT"

	cd /vagrant/
	git init
fi

###########
# Gitignore
if ! [ -f /vagrant/.gitignore ]; then
	echo "Creating .gitignore"

	cat > /vagrant/.gitignore << EOL
# Our ignores
.htaccess
.vagrant
ubuntu-bionic-18.04-cloudimg-console.log
db.sql

# Ignore non essential plugins
wp-content/plugins/*
!wp-content/plugins/advanced-custom-fields-pro
!wp-content/plugins/sitepress-multilingual-cms

# Ignore WP core
*~
.DS_Store
.svn
.cvs
*.bak
*.swp
Thumbs.db

# wordpress specific
wp-config.php
wp-content/uploads/
wp-content/blogs.dir/
wp-content/upgrade/*
wp-content/backup-db/*
wp-content/advanced-cache.php
wp-content/wp-cache-config.php
wp-content/cache/*
wp-content/cache/supercache/*

# wpengine specific
.smushit-status
.gitattributes
_wpeprivate
wp-content/object-cache.php
wp-content/mu-plugins/mu-plugin.php
wp-content/mu-plugins/slt-force-strong-passwords.php
wp-content/mu-plugins/limit-login-attempts
wp-content/mu-plugins/wpengine-common
wp-content/mysql.sql

# wp core (as of 3.4.1)
/db-config.php
/index.php
/license.txt
/readme.html
/wp-activate.php
/wp-app.php
/wp-atom.php
/wp-blog-header.php
/wp-comments-post.php
/wp-commentsrss2.php
/wp-config-sample.php
/wp-cron.php
/wp-feed.php
/wp-links-opml.php
/wp-load.php
/wp-login.php
/wp-mail.php
/wp-rdf.php
/wp-rss.php
/wp-rss2.php
/wp-pass.php
/wp-register.php
/wp-settings.php
/wp-signup.php
/wp-trackback.php
/xmlrpc.php
/wp-admin
/wp-includes
/wp-content/index.php
/wp-content/themes/twentyten
/wp-content/themes/index.php
/wp-content/plugins/index.php

# large/disallowed file types
# a CDN should be used for these
*.hqx
*.bin
*.exe
*.dll
*.deb
*.dmg
*.iso
*.img
*.msi
*.msp
*.msm
*.mid
*.midi
*.kar
*.mp3
*.ogg
*.m4a
*.ra
*.3gpp
*.3gp
*.mp4
*.mpeg
*.mpg
*.mov
*.webm
*.flv
*.m4v
*.mng
*.asx
*.asf
*.wmv
*.avi
EOL
fi

##########
# Htaccess
if ! [ -f /vagrant/.htaccess ]; then
	echo "Creating .htaccess"

	cat > /vagrant/.htaccess << EOL
php_value upload_max_filesize 64M
php_value post_max_size 64M

<IfModule mod_rewrite.c>
	RewriteEngine On
	RewriteBase /
	RewriteRule ^index.php\$ - [L]
	RewriteCond %{REQUEST_FILENAME} !-f
	RewriteCond %{REQUEST_FILENAME} !-d
	RewriteRule . /index.php [L]
</IfModule>
EOL
fi

###########
# WordPress
# NOTE: I think maybe this too creates (or adds to) .htaccess...
if ! [ -d /vagrant/wp-admin/ ]; then
	wp core download --skip-content --path=/vagrant/

	# Install sv_SE
	wp language core install sv_SE --path=/vagrant/
	wp language core activate sv_SE --path=/vagrant/
fi

###########
# WP Config
if ! [ -f /vagrant/wp-config.php ]; then
	echo "Creating wp-config.php"

	wp config create --dbname=$DBNAME --dbprefix=$DBPREFIX --dbuser=root --dbpass=root --dbhost=localhost --quiet --path=/vagrant/
	wp config set WP_DEBUG true --raw --type=constant --path=/vagrant/
fi

#################
# Create database
mysql -uroot -proot -e "CREATE DATABASE IF NOT EXISTS ${DBNAME}"

# We have an existing DB dump
if [ -f /vagrant/db.sql ]; then
	echo "Importing existing database"

	# Make sure not duplicate DB
	mysql -uroot -proot -e "DROP DATABASE ${DBNAME}"
	mysql -uroot -proot -e "CREATE DATABASE ${DBNAME}"

	# Import existing DB
	mysql -uroot -proot $DBNAME < /vagrant/db.sql

	# Check db prefix
	DBPREFIX=$(mysql $DBNAME -uroot -proot -sse "SELECT DISTINCT SUBSTRING(TABLE_NAME FROM 1 FOR (LENGTH(TABLE_NAME) - 8)) FROM information_schema.TABLES WHERE TABLE_NAME LIKE '%postmeta'")

	if ! [ $DBPREFIX = "wp_" ]; then
		echo "Changing DB prefix to $DBPREFIX"

		wp config set table_prefix $DBPREFIX --path=/vagrant/
	fi

	# Rewrite site_url if needed
	# TODO: Should rewrite https://www.siteurl.com, https://siteurl.com, http://www.siteurl.com and http://siteurl.com just to be sure
	CURRSITEURL=$(mysql $DBNAME -uroot -proot -sse "SELECT option_value FROM ${DBPREFIX}options WHERE option_name = 'siteurl'")

	if ! [ $CURRSITEURL = $SITEURL ]; then
		echo "Rewriting siteurl from $CURRSITEURL to $SITEURL"

		wp search-replace $CURRSITEURL $SITEURL --path=/vagrant/

		# Route wp-content to live site
		cat > /vagrant/.htaccess << EOL
php_value upload_max_filesize 64M
php_value post_max_size 64M

<IfModule mod_rewrite.c>
	RewriteEngine On
	RewriteBase /

	# Route wp-content to live site
	RewriteCond %{REQUEST_URI} ^/wp-content/uploads/[^\/]*/.*\$
	RewriteRule ^(.*)\$ $CURRSITEURL/\$1 [QSA,L]

	RewriteRule ^index.php\$ - [L]
	RewriteCond %{REQUEST_FILENAME} !-f
	RewriteCond %{REQUEST_FILENAME} !-d
	RewriteRule . /index.php [L]
</IfModule>
EOL
	fi
# No dump, fresh install
else
	echo "Doing fresh install"

	wp core install --url=$SITEURL --title=$SITENAME --admin_user=siteadmin --admin_password=password --admin_email=me@mydomain.com --skip-email --path=/vagrant/

	# Create start and blog page
	wp post update 2 --post_title=Start --post_name=start --post_content="Välkommen!" --path=/vagrant/
	BLOGID=$(wp post create --post_type=page --post_status=publish --post_author=1 --post_name=blogg --post_title=Blogg --post_content="Välkommen till bloggen!" --porcelain --path=/vagrant/)

	# Use static front page
	wp option update show_on_front 'page' --path=/vagrant/
	wp option update page_on_front 2 --path=/vagrant/ # NOTE: Risky to hard-code 2?? It's the default "Sample page" created by a fresh install...
	wp option update page_for_posts $BLOGID --path=/vagrant/

	# Update permalink structure
	wp option update permalink_structure "/blogg/%postname%/" --path=/vagrant/

	# Disable comments
	wp option update default_comment_status closed --path=/vagrant/

	# Time/date formats
	wp option update date_format "j F, Y" --path=/vagrant/
	wp option update time_format "H:i" --path=/vagrant/
fi

############
# WP Content
if ! [ -d /vagrant/wp-content/ ]; then
	echo "Creating wp-content/"

	mkdir /vagrant/wp-content/
fi

# Plugins
if ! [ -d /vagrant/wp-content/plugins/ ]; then
	echo "Creating wp-content/plugins/"

	mkdir /vagrant/wp-content/plugins/
fi

# Uploads
if ! [ -d /vagrant/wp-content/uploads/ ]; then
	echo "Creating wp-content/uploads/"

	mkdir /vagrant/wp-content/uploads/
fi

chmod 777 /vagrant/wp-content/uploads/

# Themes
if ! [ -d /vagrant/wp-content/themes/ ]; then
	echo "Creating wp-content/themes/"

	mkdir /vagrant/wp-content/themes

	# Install Sleek
	echo "Installing Sleek"

	cd /vagrant/

	git submodule add https://github.com/powerbuoy/sleek wp-content/themes/sleek

	# Install SleekChild
	echo "Installing SleekChild"

	wp theme install https://github.com/powerbuoy/sleek-child/archive/master.zip --path=/vagrant/

	# Rename SleekChild
	mv /vagrant/wp-content/themes/sleek-child/ /vagrant/wp-content/themes/$THEMENAME

	# Search/replace textdomains
	sed -i -e "s/SleekChild/${SITENAME}/g" /vagrant/wp-content/themes/$THEMENAME/style.css
	sed -i -e "s/sleek_child/${THEMENAME}/g" /vagrant/wp-content/themes/$THEMENAME/style.css
	sed -i -e "s/sleek_child/${THEMENAME}/g" /vagrant/wp-content/themes/$THEMENAME/functions.php

	# Activate theme
	wp theme activate $THEMENAME --path=/vagrant/

	# NPM install & gulp
	echo "Running NPM install and Gulp on ${THEMENAME} (this may take a while...)"

	cd /vagrant/wp-content/themes/$THEMENAME

	npm install
	gulp

	# Create sleek-css config
	cat /vagrant/wp-content/themes/$THEMENAME/node_modules/sleek-css/config/*.scss > /vagrant/wp-content/themes/$THEMENAME/src/sass/config.scss
	sed 's/ !default//g' /vagrant/wp-content/themes/$THEMENAME/src/sass/config.scss
fi

# Run NPM install on sleek with package.json and no node_modules
if [ -f /vagrant/wp-content/themes/sleek/package.json ] && [ ! -d /vagrant/wp-content/themes/sleek/node_modules ]; then
	echo "Running NPM install on Sleek (this may take a while...)"

	cd /vagrant/wp-content/themes/sleek

	npm install
fi

# Run NPM install and Gulp on existing themes with package.json and no node_modules
if [ -f /vagrant/wp-content/themes/$THEMENAME/package.json ] && [ ! -d /vagrant/wp-content/themes/$THEMENAME/node_modules ]; then
	echo "Running NPM install and Gulp on ${THEMENAME} (this may take a while...)"

	cd /vagrant/wp-content/themes/$THEMENAME

	npm install
	gulp
fi

echo "All done! Visit your site at: $SITEURL"
