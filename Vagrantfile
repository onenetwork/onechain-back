# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/trusty64"

  config.vm.network "forwarded_port", guest: 8545, host: 8545
  config.vm.network "private_network", ip: "192.168.201.55"

  config.vm.synced_folder "C:/views/onechain-back", "/vagrant", type: "virtualbox"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
  end

  config.vm.provision :shell, inline: <<-SHELL
    sudo apt-get update
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
     
    # Hyperledger dependencies; see https://chainhero.io/2018/03/tutorial-build-blockchain-app-2/
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt update
    sudo apt install -y docker-ce
    sudo groupadd docker
    sudo gpasswd -a ${USER} docker
    sudo service docker restart
    sudo curl -L https://github.com/docker/compose/releases/download/1.18.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    wget --progress=dot:giga https://storage.googleapis.com/golang/go1.9.2.linux-amd64.tar.gz && \
    sudo tar -C /usr/local -xzf go1.9.2.linux-amd64.tar.gz && \
    rm go1.9.2.linux-amd64.tar.gz && \
    echo 'export PATH=/usr/local/go/bin:$PATH' | sudo tee -a /etc/profile && \
    echo 'export GOPATH=$HOME/go' | tee -a $HOME/.bashrc && \
    echo 'export PATH=$GOROOT/bin:$GOPATH/bin:$PATH' | tee -a $HOME/.bashrc && \
    export GOPATH=$HOME/go
    export PATH=/usr/local/go/bin:$GOROOT/bin:$GOPATH/bin:$PATH
    mkdir -p $HOME/go/{src,pkg,bin}
    
    go get -u github.com/hyperledger/fabric-sdk-go && \
    cd $GOPATH/src/github.com/hyperledger/fabric-sdk-go && \
    git checkout 614551a752802488988921a730b172dada7def1d
    
    cd $GOPATH/src/github.com/hyperledger/fabric-sdk-go && \
    make depend-install
    
    cd $GOPATH/src/github.com/hyperledger/fabric-sdk-go ; \
    make

    # Install gradle
    wget --progress=dot:giga https://services.gradle.org/distributions/gradle-4.2.1-bin.zip
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

    sudo printf "\n192.168.201.55\tbackchain-vagrant.onenetwork.com\n" >> /etc/hosts
    
    printf ". ~/.bashrc\ncd /vagrant\n. .env.sh\n" >> /home/vagrant/.bash_profile
    mkdir /home/vagrant/log
     
    sudo chown -R vagrant /home/vagrant
    
    sudo su - vagrant
    cd /vagrant
    sudo su - vagrant -c 'bk start'

    printf "\n\n=== Provisioning Complete ===\n"
  SHELL
end
