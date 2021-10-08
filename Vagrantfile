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

# Verify Ansible version requirement.
provisioner = vconfig['force_ansible_local'] ? :ansible_local : vagrant_provisioner
if provisioner == :ansible
  require_ansible_version ">= #{vconfig['project_ansible_version_min']}"
end

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

  # Sync the project root directory to /vagrant
  unless vconfig['vagrant_synced_folders'].any? { |synced_folder| synced_folder['destination'] == '/vagrant' }
    vconfig['vagrant_synced_folders'].push(
      'local_path' => host_project_dir,
      'destination' => '/vagrant'
    )
  end

  # Synced folders.
  vconfig['vagrant_synced_folders'].each do |synced_folder|
    options = {
      type: synced_folder.fetch('type', vconfig['vagrant_synced_folder_default_type']),
      rsync__exclude: synced_folder['excluded_paths'],
      rsync__args: ['--verbose', '--archive', '--delete', '-z', '--copy-links', '--chmod=ugo=rwX'],
      id: synced_folder['id'],
      create: synced_folder.fetch('create', false),
      mount_options: synced_folder.fetch('mount_options', []),
      nfs_udp: synced_folder.fetch('nfs_udp', false)
    }
    synced_folder.fetch('options_override', {}).each do |key, value|
      options[key.to_sym] = value
    end
    config.vm.synced_folder synced_folder.fetch('local_path'), synced_folder.fetch('destination'), options
  end

  # Prepare playbook
  if provisioner == :ansible
    playbook = "#{host_projectvm_dir}/provisioning/playbook.yml"
    config_dir = host_config_dir
  else
    playbook = "#{guest_projectvm_dir}/provisioning/playbook.yml"
    config_dir = guest_config_dir
  end

  # Ansible.
  config.vm.provision 'projectvm', type: provisioner do |ansible|
    ansible.compatibility_mode = '2.0'
    ansible.playbook = playbook
    ansible.extra_vars = {
      config_dir: config_dir,
      projectvm_env: projectvm_env,
      ansible_python_interpreter: vconfig['ansible_python_interpreter']
    }
    ansible.raw_arguments = Shellwords.shellsplit(ENV['PROJECTVM_ANSIBLE_ARGS']) if ENV['PROJECTVM_ANSIBLE_ARGS']
    ansible.tags = ENV['PROJECTVM_ANSIBLE_TAGS']
    # Use pip to get the latest Ansible version when using ansible_local.
    provisioner == :ansible_local && ansible.install_mode = 'pip3'
  end

end
