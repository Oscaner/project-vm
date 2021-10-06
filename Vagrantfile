# frozen_string_literal: true

# -*- mode: ruby -*-
# vi: set ft=ruby :

require_relative 'lib/projectvm/vagrant'

# Absolute paths on the host machine.
host_projectvm_dir = File.dirname(File.expand_path(__FILE__))
host_project_dir = ENV['PROJECTVM_PROJECT_ROOT'] || host_projectvm_dir
host_config_dir = ENV['PROJECTVM_CONFIG_DIR'] ? "#{host_project_dir}/#{ENV['PROJECTVM_CONFIG_DIR']}" : host_project_dir

# Absolute paths on the guest machine.
guest_project_dir = '/vagrant'
guest_projectvm_dir = ENV['PROJECTVM_DIR'] ? "/vagrant/#{ENV['PROJECTVM_DIR']}" : guest_project_dir
guest_config_dir = ENV['PROJECTVM_CONFIG_DIR'] ? "/vagrant/#{ENV['PROJECTVM_CONFIG_DIR']}" : guest_project_dir

projectvm_env = ENV['PROJECTVM_ENV'] || 'vagrant'

# Absolute config file path.
default_config_file = "#{host_projectvm_dir}/default.config.yml"
unless File.exist?(default_config_file)
  raise_message "Configuration file not found! Expected in #{default_config_file}"
end

# Get vconfig.
vconfig = load_config(
  [
    default_config_file,
    "#{host_config_dir}/config.yml",
    "#{host_config_dir}/#{projectvm_env}.config.yml",
    "#{host_config_dir}/local.config.yml"
  ]
)

# Verify Vagrant version requirement.
Vagrant.require_version ">= #{vconfig['project_vagrant_version_min']}"

# Ensure vagrant plguins.
ensure_plugins(vconfig['vagrant_plugins'])

Vagrant.configure('2') do |config|
  # Set the name of the VM.
  # @see http://stackoverflow.com/a/17864388/100134
  config.vm.define vconfig['vagrant_machine_name']

  # Networking configuration.
  config.vm.hostname = vconfig['vagrant_hostname']
  config.vm.network :private_network,
                    ip: vconfig['vagrant_ip'],
                    auto_network: vconfig['vagrant_ip'] == '0.0.0.0' && Vagrant.has_plugin?('vagrant-auto_network')

  unless vconfig['vagrant_public_ip'].empty?
    config.vm.network :public_network,
                      ip: vconfig['vagrant_public_ip'] != '0.0.0.0' ? vconfig['vagrant_public_ip'] : nil
  end

  # SSH options.
  config.ssh.insert_key = false
  config.ssh.forward_agent = true

  # Vagrant box.
  config.vm.box = vconfig['vagrant_box']

  # Display an introduction message after `vagrant up` and `vagrant provision`.
  config.vm.post_up_message = vconfig.fetch('vagrant_post_up_message', get_default_post_up_message(vconfig))

end
