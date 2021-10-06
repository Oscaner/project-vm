# frozen_string_literal: true

require 'yaml'

# Return the combined configuration content all files provided.
def load_config(files)
  vconfig = {}
  files.each do |config_file|
    if File.exist?(config_file)
      optional_config = YAML.load_file(config_file)
      vconfig.merge!(optional_config) if optional_config
    end
  end
  resolve_jinja_variables(vconfig)
end

# Resolve jinja variables in hash.
def resolve_jinja_variables(vconfig)
  walk(vconfig) do |value|
    while value.is_a?(String) && value.match(/{{ .* }}/)
      value = value.gsub(/{{ (.*?) }}/) { vconfig[Regexp.last_match(1)] }
    end
    value
  end
end

def ensure_plugins(plugins)
  logger = Vagrant::UI::Colored.new
  installed = false

  plugins.each do |plugin|
    plugin_name = plugin['name']
    manager = Vagrant::Plugin::Manager.instance

    next if manager.installed_plugins.key?(plugin_name)

    logger.warn("Installing plugin #{plugin_name}")

    manager.install_plugin(
      plugin_name,
      sources: plugin.fetch('source', %w[https://rubygems.org/ https://gems.hashicorp.com/]),
      version: plugin['version']
    )

    installed = true
  end

  return unless installed

  logger.warn('`vagrant up` must be re-run now that plugins are installed')
  exit
end

# Return a default post_up_message.
def get_default_post_up_message(vconfig)
  'Your Project VM Vagrant box is ready to use!'\
    "\n* Visit the dashboard for an overview of your site: http://dashboard.#{vconfig['vagrant_hostname']} (or http://#{vconfig['vagrant_ip']})"\
    "\n* You can SSH into your machine with `vagrant ssh`."\
    "\n* Find out more in the Project VM documentation at http://projectvm.oscaner.com"
end

# Recursively walk an tree and run provided block on each value found.
def walk(obj, &function)
  if obj.is_a?(Array)
    obj.map { |value| walk(value, &function) }
  elsif obj.is_a?(Hash)
    obj.each_pair { |key, value| obj[key] = walk(value, &function) }
  else
    obj = yield(obj)
  end
end
