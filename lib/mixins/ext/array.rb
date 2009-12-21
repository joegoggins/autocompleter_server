class ArrayElementDoesNotRespondToToAutocompleter < StandardError; end

module Mixins
  module Ext
    module Array
      def to_autocompleter_json(options)
        autocompleterified_json_array = []
        self.each do |x|
          if x.respond_to? :to_autocompleter_json
            autocompleterified_json_array << x.to_autocompleter_json(options)
          else
            raise ArrayElementDoesNotRespondToToAutocompleter
          end
        end
        "[#{autocompleterified_json_array.join(',')}]"
      end
    end
  end
end
  
  
