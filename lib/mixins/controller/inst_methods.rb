class QRequired < Exception
end

class AutocompleterJavascriptSubClassRequired < Exception
end

class WhereSqlSnippetsMustBeArray < Exception
end

module Mixins
  module Controller
    module InstMethods
      # == Mandatory Params
      #   - params[:q]
      #     - A string to query the database, returns json like:
      #
      # == Options Params
      #   - params[:uniq_column_name]
      #      - This is the column that will be used as the unique identifier for results/searches
      #   - params[:max_results] default to 25
      #      - Must be less then Model.max_results
      #   - params[:columns_to_submit_against]
      #      - These are the columns upon which q is compared against, defaulted to all
      #      - Must be a subset of Model::autocomplete_columns
      #   - params[:columns_to_show]
      #      - These are the columns to return as a result set, defaulted to all
      #      - Must be a subset of Model::autocomplete_columns
      #   
      def autocompleter_submit
        params[:from_sql_snippet]  = ""
        params[:where_sql_snippet] = "" 

        if respond_to? :autocompleter_append_from_sql_snippet
          params[:from_sql_snippet] = autocompleter_append_from_sql_snippet
        end

        if respond_to? :autocompleter_append_where_sql_snippet
          params[:where_sql_snippet] = autocompleter_append_where_sql_snippet
        end
        
        #
        params[:additional_info] = []
        if respond_to? :autocompleter_additional_info_json_method
          params[:additional_info] = autocompleter_additional_info_json_method
        end
        
        begin
          respond_to do |format|
            options = self.class.autocompleter_model.sanitize_and_return_autocompleter_options(params)

            format.json { render :json => self.class.autocompleter_model.autocompleter_find(params).to_autocompleter_json(options) }
          end
        rescue QRequired => e
          render :text => 'Your javascript autocompleter tool must specify q in Ajax request.' and return
        end
      end
    end
  end
end

