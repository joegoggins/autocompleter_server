module Mixins
  module Routing
    module MapperExtensions
      def include_autocompleter_submits
        # This keeps the config/routes.rb simple in the engine.
        # If add_named_route usage becomes cumbersome or outdated, then move this logic to config/routes.rb
        # 
        AutocompleterServer.resources.each do |resource_name, options|

          options[:exposed_in].each do |controller|

            controller_fragment = ""
            unless controller.blank?
              controller_fragment = controller.name.split("Controller").first.underscore
            end

            path = "/#{controller_fragment}/autocompleter_submit"
            name = "#{controller_fragment}_autocompleter_submit".gsub("/", "_")

            @set.add_named_route(name, path, {:controller => "#{controller_fragment}", :action => "autocompleter_submit" })
          end
        end
      end
    end
  end
end
