class FullTextIndexRequired < Exception
end

class DoubleQuery < Exception
end

class QRequired < Exception
end

class InvalidUniqColumnName < Exception
end

class InvalidColumnName < Exception
end

class WhereSqlSnippetsMustBeArray < Exception
end




module Mixins
  module Model
    module ClassMethods
      # Resolved an the full_text_index to its columns
      # Stores this variable in the class var full_text_index_columns
      def get_columns_from_full_text_index
        if self.full_text_index_columns.blank?
          # Mysql 4 does not support the where clause appened to the SHOW INDEXES statement, SO I have reverted to the slower method below
          results = ActiveRecord::Base.connection.execute("SHOW INDEXES FROM #{self.table_name}")

          self.full_text_index_columns = [] 
          while row = results.fetch_hash do
            self.full_text_index_columns << row["Column_name"] if row["Key_name"] == autocompleter_default_options[:full_text_index]
          end
        end

        # Error out if full_text_index resolves to no columns.
        raise FullTextIndexRequired if self.full_text_index_columns.blank?

        self.full_text_index_columns 
      end

      def full_text_columns
        self.get_columns_from_full_text_index
      end

      # =Overview
      #  - Produces a find call with the condition set and limit.
      # == Query Details
      #  - Supports an "initial_selections" parameter, that gives a set of JSON encoded unique ids
      #  - The query is always (ONE OR THE OTHER) (for a basic params[:q] = the query search)
      #    - either LIKE based joined with OR's or (
      #      - happens if 
      #         - q length is less than N chars long or
      #    - A single full-text search defined server side
      #  - The Result Set has to_autocompleter_json called upon it
      # == Exceptions
      #  - raises AutoCompleteQRequired if q not specified.
      #
      def autocompleter_find(controller_params)
        options = sanitize_and_return_autocompleter_options(controller_params)

        # TODO OPTIMIZE: Inject to the array class here ... at the instance level. the to_autocompleter_json method
        # Originally, I was considered that extending the result class was a step that might take noticable time,
        # hence just extending the array class. If a performance issue arises, we can look at this again.

        if not options[:initial_selections].blank?
          self.perform_initial_selections_query(options).extend(Mixins::Ext::Array)
        elsif options[:min_full_text_search_q_length].blank? or options[:q].length < options[:min_full_text_search_q_length]
          self.perform_like_query(options).extend(Mixins::Ext::Array)
        else  # q.length >= options[:min...] 
          self.perform_full_text_query(options).extend(Mixins::Ext::Array)
        end
      end

      # Reconciles the controller gathered options and the defaults to ensure things are all good
      # 
      def sanitize_and_return_autocompleter_options(options)
        return_this = {}
        return_this[:min_full_text_search_q_length] = autocompleter_default_options[:min_full_text_search_q_length]

        if !options[:q].blank? and !options[:initial_selections].blank?   
          # TODO Silent or not? -- Assuming not.
          raise DoubleQuery, "You have provided a query and initial_selections. Which did you intend?"      
        end
     
        if options[:q].blank? and options[:initial_selections].blank?
          raise QRequired, "You must specify a :q or :initial_selections parameter to the autocompleter"
        elsif options[:q]
          return_this[:q] = options[:q]
        else
          if options[:initial_selections].is_a? String
            return_this[:initial_selections] = ActiveSupport::JSON.decode(options[:initial_selections]) 
          else
            return_this[:initial_selections] = options[:initial_selections] 
          end
        end
        
        return_this[:additional_info] = options[:additional_info]

        if autocompleter_default_options[:possible_column_names].include?(options[:uniq_column_name])   # TODO This is only verifying if client sent a column_name
          # DO WE WANT to allow clients to send in a method name?
          # Check for valid uniq_column_name -- As in at least a valid column.
          if !autocompleter_default_options[:possible_column_names].include? options[:uniq_column_name]
            # TODO Silent or not? -- Assuming not.
            raise InvalidUniqColumnName, "You have specified an invalid uniq_column_name"
          end
          return_this[:uniq_column_name] = options[:uniq_column_name]
        else
          return_this[:uniq_column_name] = autocompleter_default_options[:uniq_column_name] 
        end
        
        if options[:columns_to_show].blank?# ||
          #(options[:columns_to_show] - autocompleter_default_options[:possible_column_names]).empty?
          return_this[:columns_to_show] = autocompleter_default_options[:columns_to_show]
        else
          # Check for valid columns
          options[:columns_to_show].each do |col|
            if !autocompleter_default_options[:possible_column_names].include? col
              # TODO Silent or not? -- Assuming not.
              # raise InvalidColumnName, "You have specified an invalid column name in columns_to_show."
            end
          end

          if options[:columns_to_show].is_a? String 
            return_this[:columns_to_show] = ActiveSupport::JSON.decode(options[:columns_to_show])   
          else
            return_this[:columns_to_show] = options[:columns_to_show]   
          end
        end
      
        if options[:max_results].blank? || 
          options[:max_results] > autocompleter_default_options[:max_results]
          return_this[:max_results] = autocompleter_default_options[:max_results]
        else
          return_this[:max_results] = options[:max_results]
        end 
      
        # Controller can specify an array, same format as expected by ActiveRecords::sanitize_sql_from_conditions,
        # to constrain the query further than the full text query
        #
        if options[:where_sql_snippet].blank?
          return_this[:where_sql_snippet] = []
        elsif (not options[:where_sql_snippet].kind_of? Array)
          raise WhereSqlSnippetsMustBeArray
        else
          return_this[:where_sql_snippet] = options[:where_sql_snippet]
        end

        unless options[:from_sql_snippet].blank?
          return_this[:from_sql_snippet] = options[:from_sql_snippet]
        end
        
        return return_this
      end

      def perform_like_query(options)
        max_results = options[:max_results]
        q = options[:q]

        conditions = []
        autocompleter_default_options[:possible_column_names].each do |column|
          conditions << "#{self.table_name}.#{column.to_s} LIKE :q"
        end
        q = "#{q}%"
       
        condition = ["(#{conditions.join(" OR ")})", {:q => "#{q}"}]
       
        # Add further constraints
        #
        condition.first << " AND #{sanitize_sql_for_conditions(options[:where_sql_snippet])}" unless options[:where_sql_snippet].blank?

        select = " DISTINCT " + (autocompleter_default_options[:possible_column_names].map {|col_name| "#{self.table_name}.#{col_name}"}).join(", ")
        
        froms = self.table_name
        froms << " #{options[:from_sql_snippet]}" unless options[:from_sql_snippet].blank?
        
       
        self.find(:all, :select => select, :from => froms, :conditions => condition, :limit => max_results)
      end

      # returns a hash with keys for each relevant query component
      #
      def build_full_text_query(options)
        q = prepare_full_text_query_string(options[:q])

        cols = self.full_text_columns.map {|c| "#{self.table_name}.#{c.to_s}"}.join(", ")
        full_text_condition = " MATCH(#{cols}) AGAINST(:q IN BOOLEAN MODE) "
        
        # Add further constraints
        #
        condition = " WHERE #{sanitize_sql_for_conditions(options[:where_sql_snippet])}" unless options[:where_sql_snippet].blank?
       
        
        selects = autocompleter_default_options[:possible_column_names].map {|col_name| "#{self.table_name}.#{col_name}"} 
        selects << "#{full_text_condition} AS RELEVANCE"
        selects << "#{self.table_name}.#{autocompleter_default_options[:uniq_column_name]} AS UNIQ_COLUMN"
        select = " DISTINCT " + selects.join(", ")

        froms = self.table_name
        froms << " #{options[:from_sql_snippet]}" unless options[:from_sql_snippet].blank?

        order = "RELEVANCE DESC" 
        query_components = {:select => select, :from => froms, :where => condition, :order => order, :limit => options[:max_results], :q => q}
      end
      
      # Prepare the search string for full text matching
      #   Turns 'these three words' into
      #   '+these* +three* +words*'
      #   Signifying all matches should have all 3 words, with a wildcard on the end of each word
      #
      # To change the search method for a specific model, define this method in that model and return a string for
      # how the search should be performed.
      #
      # The match bit, is an effort to avoid interpretting mysql boolean special chars as such.
      # When looking for someone with an x500 of t-gang, t-skog, or t-harr, you will need to type the whole thing.
      # We've tried many other ways of doing it...the jist of it is: If you include a "-" in your word, you must include the whole word, the partial match say for "t-sko" does not work. 
      # This was done to accommodate ASR's autocompleters on RT.  They have a greasemonkey script they use that needs to be able to do a one to one look up on x500.
      # The dashes were tripping them up.
      #
      def prepare_full_text_query_string(q)
        words = q.split # splits query on whitespace
        words.map! do |w|
          if w.match /\w+-\w+/ # If there is a special mysql char in the word, quote it.  Currently only doing '-' might need to add others later.
            "+\"#{w}\"*"
          else
            "+#{w}*"            
          end
        end
        words.join(" ")
      end
      
      def perform_full_text_query(options)
        query_components = build_full_text_query(options)          
        self.find_by_sql [
          "SELECT #{query_components[:select]} 
           FROM #{query_components[:from]} 
           #{query_components[:where]} 
           HAVING RELEVANCE > 0 OR UNIQ_COLUMN = :q
           ORDER BY #{query_components[:order]} 
           LIMIT 0, #{query_components[:limit]}", {:q => "#{query_components[:q]}"} ]
      end

      def perform_initial_selections_query(options)
        initials = options[:initial_selections].to_s.split(",")
        max_results = initials.size.to_s  # This could potentially supercede the server setting on max results -- Do we want that?

        return [] if max_results == "0"

        condition = ["#{options[:uniq_column_name]} IN (?)", initials]
        self.find(:all, :conditions => condition, :limit => max_results)
      end
    end
  end
end
