# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/trusty64"

  config.vm.network "private_network", ip: "55.55.55.55"

  config.vm.synced_folder "E:/views/onechain-back", "/vagrant", type: "virtualbox"

  config.vm.provider "virtualbox" do |vb|
     vb.memory = "2048"
  end

  config.vm.provision :shell, inline: <<-SHELL
     sudo apt-get -y install g++
     sudo apt-get -y install golang
     sudo apt-get -y install git

     # Install node.js
     curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
     sudo apt-get -y install nodejs
     sudo apt-get -y install npm

     # Install various etherium tools
     sudo npm install -g sync-exec
     sudo npm install -g ethereumjs-testrpc
     sudo npm install -g solc
     sudo npm install -g web3
     sudo npm install -g truffle@3.4.3

     printf ". ~/.bashrc\ncd /vagrant\n. .env.sh\n" >> /home/vagrant/.bash_profile
     mkdir /home/vagrant/log
     
     sudo chown -R vagrant /home/vagrant

     echo '=== Provisioning Complete ==='
  SHELL
end
