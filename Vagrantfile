# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
	# Ubuntu 18.04
	config.vm.box = "ubuntu/bionic64"

	# Access your site at localhost:8080
	config.vm.network :forwarded_port, guest: 80, host: 8080

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

	# Install Apache, PHP, MySQL etc
	config.vm.provision "lamp", type: "shell", path: "https://raw.githubusercontent.com/powerbuoy/sleek-vagrantfile/master/lamp.sh"

	# Setup WordPress, Themes and DataBase
	config.vm.provision "wordpress", type: "shell", privileged: false, args: [File.basename(File.dirname(__FILE__))], path: "https://raw.githubusercontent.com/powerbuoy/sleek-vagrantfile/master/wordpress.sh"
end
