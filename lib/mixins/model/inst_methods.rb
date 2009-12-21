module Mixins
  module Model 
    module InstMethods
      def to_autocompleter_json(options)
        options = self.class.sanitize_and_return_autocompleter_options(options)
        column_values_to_show = []
        additional_info_to_show = []
        options[:columns_to_show].each do |x|
          column_values_to_show << [x, self.send(x)]
        end    
        options[:additional_info].each do |x|
          additional_info_to_show << [x, self.send(x)]
        end
        {:uniq_column_value => self.send(options[:uniq_column_name]),
         :columns_to_show => column_values_to_show,
         :additional_info => additional_info_to_show
         }.to_json
      end
    end
  end
end
