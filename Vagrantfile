# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  ##############
  # Ubuntu 18.04
  config.vm.box = "ubuntu/bionic64"

  ####################################
  # Access your site at localhost:8080
  config.vm.network :forwarded_port, guest: 80, host: 8080

  ####################
  # Save DB on destroy
  config.trigger.before :destroy do |trigger|
    trigger.run_remote = {
      args: [File.basename(File.dirname(__FILE__))],
      inline: <<-SHELL
          DBNAME="wp_$1"
          mysqldump -uroot -proot $DBNAME > /vagrant/db.sql
        SHELL
    }
  end

  ################################
  # Install Apache, PHP, MySQL etc
  config.vm.provision "shell", inline: <<-SHELL
    ######################
    # Don't remove this :P
    apt-get update

    ################
    # Install apache
    apt-get install -y apache2

    #############
    # Install PHP
    apt-get install -y php

    ###############
    # Install MySQL
    debconf-set-selections <<< "mysql-server mysql-server/root_password password root"
    debconf-set-selections <<< "mysql-server mysql-server/root_password_again password root"
    apt-get -y install mysql-server

    #####################
    # Install PHP modules
    apt-get install -y php-pear php-fpm php-dev php-zip php-curl php-xmlrpc php-gd php-mysql php-mbstring php-xml libapache2-mod-php

    ####################
    # Enable mod rewrite
    a2enmod rewrite

    ################
    # Restart apache
    systemctl restart apache2

    ##################
    # Symlink /var/www
    if ! [ -L /var/www/html ]; then
      rm -rf /var/www/html
      ln -fs /vagrant /var/www/html
    fi

    ##############
    # Install curl
    apt-get install -y curl

    ##############
    # Install node
    curl -sL https://deb.nodesource.com/setup_11.x | sudo -E bash -
    apt-get install -y nodejs

    ##############
    # Install gulp
    npm install --global gulp-cli

    #############
    # Install git
    apt-get install git

    #######################
    # Install WordPress CLI
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp

    # And this fine package
    wp package install iandunn/wp-cli-rename-db-prefix
  SHELL

  ######################################
  # Setup WordPress, Themes and DataBase
  config.vm.provision "shell", privileged: false, args: [File.basename(File.dirname(__FILE__))], inline: <<-SHELL
    THEMENAME=$1
    SITENAME="${THEMENAME^}"
    DBNAME="wp_$THEMENAME"
    DBPREFIX="wp_"

    ###########
    # Setup GIT
    if ! [ -d /vagrant/.git ]; then
      cd /vagrant/
      git init
    fi

    ###########
    # Gitignore
    if ! [ -f /vagrant/.gitignore ]; then
      printf "# Our ignores\n.htaccess\n.vagrant\nubuntu-bionic-18.04-cloudimg-console.log\ndb.sql\n\n# Ignore WP core\n*~\n.DS_Store\n.svn\n.cvs\n*.bak\n*.swp\nThumbs.db\n\n# wordpress specific\nwp-config.php\nwp-content/uploads/\nwp-content/blogs.dir/\nwp-content/upgrade/*\nwp-content/backup-db/*\nwp-content/advanced-cache.php\nwp-content/wp-cache-config.php\nwp-content/cache/*\nwp-content/cache/supercache/*\n\n# wpengine specific\n.smushit-status\n.gitattributes\n_wpeprivate\nwp-content/object-cache.php\nwp-content/mu-plugins/mu-plugin.php\nwp-content/mu-plugins/slt-force-strong-passwords.php\nwp-content/mu-plugins/limit-login-attempts\nwp-content/mu-plugins/wpengine-common\nwp-content/mysql.sql\n\n# wp core (as of 3.4.1)\n/db-config.php\n/index.php\n/license.txt\n/readme.html\n/wp-activate.php\n/wp-app.php\n/wp-atom.php\n/wp-blog-header.php\n/wp-comments-post.php\n/wp-commentsrss2.php\n/wp-config-sample.php\n/wp-cron.php\n/wp-feed.php\n/wp-links-opml.php\n/wp-load.php\n/wp-login.php\n/wp-mail.php\n/wp-rdf.php\n/wp-rss.php\n/wp-rss2.php\n/wp-pass.php\n/wp-register.php\n/wp-settings.php\n/wp-signup.php\n/wp-trackback.php\n/xmlrpc.php\n/wp-admin\n/wp-includes\n/wp-content/index.php\n/wp-content/themes/twentyten\n/wp-content/themes/index.php\n/wp-content/plugins/index.php\n\n# large/disallowed file types\n# a CDN should be used for these\n*.hqx\n*.bin\n*.exe\n*.dll\n*.deb\n*.dmg\n*.iso\n*.img\n*.msi\n*.msp\n*.msm\n*.mid\n*.midi\n*.kar\n*.mp3\n*.ogg\n*.m4a\n*.ra\n*.3gpp\n*.3gp\n*.mp4\n*.mpeg\n*.mpg\n*.mov\n*.webm\n*.flv\n*.m4v\n*.mng\n*.asx\n*.asf\n*.wmv\n*.avi" > /vagrant/.gitignore
    fi

    ##########
    # Htaccess
    if ! [ -f /vagrant/.htaccess ]; then
      printf "# BEGIN WordPress\n<IfModule mod_rewrite.c>\nRewriteEngine On\nRewriteBase /\nRewriteRule ^index\.php$ - [L]\nRewriteCond %%{REQUEST_FILENAME} !-f\nRewriteCond %%{REQUEST_FILENAME} !-d\nRewriteRule . /index.php [L]\n</IfModule>\n# END WordPress" > /vagrant/.htaccess;
    fi

    ###########
    # WordPress
    if ! [ -d /vagrant/wp-admin/ ]; then
      wp core download --skip-content --path=/vagrant/ --locale=sv_SE
    fi

    ###########
    # WP Config
    if ! [ -f /vagrant/wp-config.php ]; then
      wp config create --dbname=$DBNAME --dbprefix=$DBPREFIX --dbuser=root --dbpass=root --dbhost=localhost --quiet --path=/vagrant/
    fi

    #################
    # Create database
    mysql -uroot -proot -e "CREATE DATABASE IF NOT EXISTS ${DBNAME}"

    if [ -f /vagrant/db.sql ]; then
      mysql -uroot -proot $DBNAME < /vagrant/db.sql
    else
      wp core install --url=http://localhost:8080 --title=$SITENAME --admin_user=inviseadmin --admin_password=password --admin_email=me@mydomain.com --skip-email --path=/vagrant/
    fi

    ############################
    # Rewrite site_url if needed
    # TODO: Should rewrite https://www.siteurl.com, https://siteurl.com, http://www.siteurl.com and http://siteurl.com just to be sure
    SITEURL=$(mysql wp_newsite -uroot -proot -sse "SELECT option_value FROM wp_options WHERE option_name = 'siteurl'")

    if ! [ $SITEURL = "http://localhost:8080" ]; then
      wp search-replace $SITEURL "http://localhost:8080"
    fi

    ##################
    # Change DB prefix
    wp rename-db-prefix $DBPREFIX

    ############
    # WP Content
    if ! [ -d /vagrant/wp-content/ ]; then
      mkdir /vagrant/wp-content/
    fi

    # Plugins
    if ! [ -d /vagrant/wp-content/plugins/ ]; then
      mkdir /vagrant/wp-content/plugins/
    fi

    # Uploads
    if ! [ -d /vagrant/wp-content/uploads/ ]; then
      mkdir /vagrant/wp-content/uploads/
    fi

    chmod 777 /vagrant/wp-content/uploads/

    # Themes
    if ! [ -d /vagrant/wp-content/themes/ ]; then
      mkdir /vagrant/wp-content/themes

      # Install Sleek
      cd /vagrant/

      git submodule add https://github.com/powerbuoy/sleek wp-content/themes/sleek

      # Install SleekChild
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
    fi

    echo "All done! Visit your site at: http://localhost:8080"
  SHELL
end
