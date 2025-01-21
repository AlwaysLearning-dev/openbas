# -*- mode: ruby -*-
# vi: set ft=ruby :

ENV['VAGRANT_DEFAULT_PROVIDER'] = 'virtualbox'

Vagrant.configure("2") do |config|

  # Define private network
  private_network = "192.168.56"
  
  # OpenBAS Server (Ubuntu)
  config.vm.define "openbas-server" do |openbas|
    openbas.vm.box = "gusztavvargadr/ubuntu-server"
    openbas.vm.hostname = "openbas-server"
    openbas.vm.network "private_network", ip: "#{private_network}.10"
    
    # Forward OpenBAS UI port to host
    openbas.vm.network "forwarded_port", guest: 8080, host: 8080
    openbas.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
    end
    
    # Provisioning script
    openbas.vm.provision "shell", inline: <<-SHELL
# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install Docker
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce docker-compose


# Add vagrant user to the docker group
sudo usermod -aG docker vagrant

# Download OpenBAS files
mkdir -p /home/vagrant/openbas
cd /home/vagrant/openbas
curl -LJO https://raw.githubusercontent.com/AlwaysLearning-dev/openbas/main/docker-compose.yml
curl -LJO https://raw.githubusercontent.com/AlwaysLearning-dev/openbas/main/.env

# Adjust permissions
sudo chown -R vagrant:vagrant /home/vagrant/openbas

# Start the Docker Compose setup
docker compose up -d
    SHELL
  end

  # Linux Server (Ubuntu)
  config.vm.define "linux-server" do |linux|
    linux.vm.box = "gusztavvargadr/ubuntu-server"
    linux.vm.hostname = "linux-server"
    linux.vm.network "private_network", ip: "#{private_network}.20"
    linux.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
    end
    
    # Provisioning script
    linux.vm.provision "shell", inline: <<-SHELL
# Update system
sudo apt-get update
sudo apt-get upgrade -y
curl -s http://192.168.56.10:8080/api/agent/installer/openbas/linux/35356353-f346-4fbd-817a-a3d52522a2d4 | sudo sh
    SHELL
  end
  
  # Windows Agent
  config.vm.define "windows-agent" do |windows|
    windows.vm.box = "gusztavvargadr/windows-10"
    windows.vm.hostname = "windows-agent"
    windows.vm.network "private_network", ip: "#{private_network}.30"

    windows.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
      vb.gui = true
    end
    
    # Increase WinRM timeout to handle reboots
    windows.winrm.timeout = 300

    # Provision with the PowerShell script
    windows.vm.provision "shell", path: "provision.ps1"


  end
end
