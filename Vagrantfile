# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
	# Ubuntu 18.04
	config.vm.box = "ubuntu/bionic64"

	# More RAM please
	config.vm.provider "virtualbox" do |v|
		v.memory = 2048
	end

	# Use NFS
	# config.vm.synced_folder ".", "/vagrant", type: "nfs", mount_options: ["actimeo=2"] # https://www.jverdeyen.be/vagrant/speedup-vagrant-nfs/

	# Setup network
	config.vm.network "private_network", ip: "10.11.12.13"

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
	config.vm.provision "lamp",
		type: "shell",
		path: "https://raw.githubusercontent.com/powerbuoy/sleek-vagrantfile/master/lamp.sh"

	# Setup WordPress, Themes and Database
	config.vm.provision "wordpress",
		type: "shell",
		privileged: false,
		args: [
			File.basename(File.dirname(__FILE__)),
			"http://10.11.12.13" # NOTE: Same as under network setup
		],
		path: "https://raw.githubusercontent.com/powerbuoy/sleek-vagrantfile/master/wordpress.sh"
end
