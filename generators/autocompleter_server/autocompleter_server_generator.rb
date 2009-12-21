class AutocompleterServerGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.file 'initializer.rb', "config/initializers/autocompleter_server.rb"
    end
  end
end

