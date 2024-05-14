box = "ubuntu/jammy64"

common_script = <<-SCRIPT
  export DEBIAN_FRONTEND=noninteractive

  # To allow fetching logs from journalctl
  usermod -aG adm vagrant
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.define "node0" do |node|
    node.vm.box = box
    node.vm.hostname = "node0.local"
    node.vm.network :private_network, ip: "192.168.56.2"
    node.vm.provision "shell", inline: common_script

    node.vm.provision "ansible" do |ansible|
      ansible.verbose = "v"
      ansible.playbook = "bootstrap-controlplane.yml"
      ansible.compatibility_mode = "2.0"
    end
  end

  config.vm.define "node1" do |node|
    node.vm.box = box
    node.vm.network :private_network, ip: "192.168.56.3"
    node.vm.hostname = "node1.local"
    node.vm.provision "shell", inline: common_script

    node.vm.provision "ansible" do |ansible|
      ansible.verbose = "v"
      ansible.playbook = "bootstrap-workers.yml"
      ansible.compatibility_mode = "2.0"
    end
  end

  config.vm.define "node2" do |node|
    node.vm.box = box
    node.vm.network :private_network, ip: "192.168.56.4"
    node.vm.hostname = "node2.local"
    node.vm.provision "shell", inline: common_script

    node.vm.provision "ansible" do |ansible|
      ansible.verbose = "v"
      ansible.playbook = "bootstrap-workers.yml"
      ansible.compatibility_mode = "2.0"
    end

  end
end
