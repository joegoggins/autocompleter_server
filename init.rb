require File.join(File.dirname(__FILE__), 'init_hack')

# Add route helper to inject 
ActionController::Routing::RouteSet::Mapper.send :include, Mixins::Routing::MapperExtensions

# Ensure config/routes.rb is read for engine --> 2.3.2 fix
ActionController::Routing::Routes.add_configuration_file(File.join(RAILS_ROOT, 'vendor', 'plugins', 'autocompleter_server', 'config', 'routes.rb'))
