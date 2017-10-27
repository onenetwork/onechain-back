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
    sudo apt-get -y install unzip
    sudo apt-get -y install dos2unix

    # Install java
    sudo add-apt-repository ppa:webupd8team/java
    sudo apt-get update
    echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo debconf-set-selections
    sudo apt-get install -y oracle-java8-installer
     
    # Install gradle
    wget https://services.gradle.org/distributions/gradle-4.2.1-bin.zip
    sudo unzip -d /opt/gradle gradle-4.2.1-bin.zip
    
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

    sudo printf "\n55.55.55.55\tvagrant.onenetwork.com\n" >> /etc/hosts
    
    printf ". ~/.bashrc\ncd /vagrant\n. .env.sh\n" >> /home/vagrant/.bash_profile
    mkdir /home/vagrant/log
     
    sudo chown -R vagrant /home/vagrant

    echo '=== Provisioning Complete ==='
  SHELL
end
