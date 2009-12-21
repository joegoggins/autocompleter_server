class DuplicateDefinition < Exception
end

class InvalidResource < Exception
end

class AutocompleterServer
  attr_accessor :resources
  
  def initialize
    self.resources = {}
  end 
  
  def self.configure
    @@__instance__ = self.new

    begin
      yield @@__instance__
    rescue ActiveRecord::StatementInvalid; end

    
    @@__instance__.magic!
    @@__instance__
  end 
  
  def self.instance
    @@__instance__ ||= self.new
  end 
  
  def magic!
    inject_into_models!
    inject_into_controllers!
  end 

  def resource(model, options = {:defaults => {}, :exposed_in => nil})
    if options[:exposed_in].blank? 
      raise InvalidResource.new("Invalid Controllers provided for exposure of #{model}")
    end  

    if options[:defaults].blank?
      raise InvalidResource.new("Invalid defaults provided for #{model}")
    end
  
    resources[model.to_s] = {:defaults => options.delete(:defaults), :exposed_in => options.delete(:exposed_in)}
  end
  
  def inject_into_controllers!
    resources.each do |model_name, options|
      controllers = options[:exposed_in]
      controllers.each do |controller|

        controller.send :include, Mixins::Controller::InstMethods 
 
        controller.class_eval <<-CODE
          def self.autocompleter_model
            #{model_name.constantize}           
          end
        CODE

      end
    end
  end
  
  def inject_into_models!
    resources.each do |model_name, options|
      model = model_name.constantize

      model.extend(Mixins::Model::ClassMethods)
      model.send :include, Mixins::Model::InstMethods 
    
      model.class_eval <<-CODE
        class_inheritable_accessor :full_text_index_columns
      CODE

      model.class_eval <<-CODE
        def self.autocompleter_default_options
          AutocompleterServer.resources[self.to_s][:defaults]
        end
      CODE
    end
  end

  def self.method_missing(*args)
    if self.instance.respond_to?(args.first)
      self.instance.send(args.first, *args[1..-1])
    else
      super
    end
  end
end
