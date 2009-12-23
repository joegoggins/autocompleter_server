# === AutocompleterServer Configuration ===
# 
AutocompleterServer.configure do |config|
  # === Installation ===
  #   1. Create a full-text index on your autocompleter_server table called "autocompleter_full_text_index"
  #   2. Follow the example code to get stuff set up for your app.
  #
  # === Given the following config ===
  #  config.resource User, 
  #    :defaults => {
  #    :uniq_column_name              => User.primary_key,
  #    :possible_column_names         => User.column_names, 
  #    :columns_to_show               => %w(name email description),
  #    :max_results                   => 25,
  #    :min_full_text_search_q_length => 3,
  #    :full_text_index               => 'autocompleter_full_text_index'
  #  },
  #  :exposed_in => [UsersController]
  # 
  # === The following methods will be created ===
  # A route: /users/autocompleter_submit
  #
  # A controller method: /users/autocompleter_submit?q=goggins
  # yields: json digested by autocompleter_client js class
  #
  # Model class methods:
  #   - .autocompleter_find: The method the controller calls like:
  #     @things = Thing.autocompleter_find(params)
  #   - .perform_full_text_query: The secret sauce of the the auto-completer used to do funky sql things
  #                               for advanced usage.
  #
  # Model instance methods:
  #   - .to_autocompleter_json: used internally by autocompleter find to produce the json representation 
  #                             autocompleter_client is given as input.
  #     @thing.to_autocompleter_json
  #                       
  # === Explanation of Defaults ===
  #  -uniq_column_name
  #     -Used to uniquley identify the record, submitted POST value when the containing form is submitted.
  #  -possible_column_names
  #     -Access protection against columns that the client can't target in the js templates.
  #  -columns_to_show
  #     -The columns to send to autocompleter_client for rendering via js template.
  #  -max_results
  #     -Limit of the SQL query.
  #  -min_full_text_search_q_length
  #     -The number of characters recieved before switching from a LIKE to FULLTEXT query. (Make sure to meet MySQL server settings, usually 3). 
  #     -NOTE: Can set this very high for cases in which the full_text_index is absent
  #            Like querys are conducted as 'query%'
  #  -full_text_index
  #     -Name of the full_text_index the autocompleter will match against by default.
  #   
  
  
  
  # YOUR CODE GOES HERE.  un-comment this or copy the example above and give it a shot.
=begin
  config.resource User, 
    :defaults => {
    :uniq_column_name              => User.primary_key,
    :possible_column_names         => User.column_names, 
    :columns_to_show               => %w(name email description),
    :max_results                   => 25,
    :min_full_text_search_q_length => 3,
    :full_text_index               => 'autocompleter_full_text_index'
  },
  :exposed_in => [UsersController]

=end  
  
  
end
