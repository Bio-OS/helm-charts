# -*- mode: ruby -*-
# # vi: set ft=ruby :
# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

boxes = [
  {
    :name => "registry",
    :mem => "8092",
    :cpu => "8"
  }
]
# vagrant up --provider=docker
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  #config.vm.box = "generic/centos7"
  config.vm.box = "generic/ubuntu2204"
  #config.vm.box = "alvistack/ubuntu-23.04"
  #config.disksize.size = '100GB'
  # Turn off shared folders
  config.vm.synced_folder ".", "/vagrant", id: "vagrant-root", disabled: true
  # config.vm.synced_folder "/Volumes/works/github/sge/deploy_bios", "/deploy_bios"
  config.vm.provision :shell, :inline => "sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config; sudo systemctl restart sshd;", run: "always"
  #config.vm.provision "file", source: "~/.ssh/id_rsa.pub", destination: "/home/vagrant/.ssh/id_rsa.pub"
  #config.vm.provision :shell, :inline => "cat /home/vagrant/.ssh/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys", run: "always"

  boxes.each do |opts|
    config.vm.define opts[:name] do |config|
      config.vm.hostname = opts[:name]
      config.ssh.insert_key = true
      # config.ssh.password = "vagrant"
      config.vm.provider "parallels" do |prl|
        prl.memory = opts[:mem]
        prl.cpus = opts[:cpu]
      end
      # config.vm.network :public_network
      # config.vm.network "private_network", ip: opts[:eth1], auto_config: true
    end
  end
end

# vgextend ubuntu-vg /dev/sda4
# lvextend -l 100%FREE /dev/mapper/ubuntu--vg-ubuntu--lv
# resize2fs /dev/mapper/ubuntu--vg-ubuntu--lv