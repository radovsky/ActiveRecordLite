require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    param_keys = params.keys
    param_values = params.values
    
    where_string = ""
    
    param_keys.each do |k|
      where_string += k.to_s + " = ? AND "
    end
      
    
    query = <<-SQL

    SELECT
      *
    FROM
      #{self.table_name}
    WHERE
      #{where_string[0..-6]}

    SQL

    parse_all(DBConnection.execute(query, *param_values))
    
  end
end

class SQLObject
  extend Searchable
end
