require_relative 'db_connection'
require 'active_support/inflector'
#NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
#    of this project. It was only a warm up.

class SQLObject
  def self.columns
    tmi = DBConnection.execute2("SELECT * FROM #{table_name}")
    column_names = tmi.first
    @columns ||= column_names.map { |el| el.to_sym }
    
    @columns.each do |col_name|
      define_method "#{col_name}" do
        attributes["#{col_name}".to_sym]
      end
      
      define_method "#{col_name}=" do |arg|
        attributes["#{col_name}".to_sym] = arg
      end
    end
    
  end

  def self.table_name=(table_name)
    @table_name = table_name.tableize
  end

  def self.table_name
    @table_name ||= self.name.tableize
  end

  def self.all
    parse_all(
    DBConnection.execute(
    "SELECT * FROM #{name.tableize}"
    ))
  end
  
  def self.parse_all(results)
    results.map do |result|
      self.new(result)
    end
  end

  def self.find(id)
    self.new(
    DBConnection.execute(
    "SELECT * FROM #{table_name} WHERE id = (?)", id
    ).first)
  end

  def attributes
    @attributes ||= Hash.new
  end

  def insert
    question_marks = (["?"] * attribute_values.length).join(", ")
    col_names = self.class.columns.join(", ")
    
    

    query = <<-SQL

    INSERT INTO
      #{self.class.table_name} (#{col_names})
    VALUES
      (#{question_marks})

    SQL

    DBConnection.execute(query, *attribute_values)
    @attributes[:id] = DBConnection.last_insert_row_id
  end

  def initialize(params={})
    my_cols = self.class.columns
    params.each do |k, v|
      raise "unknown attribute '#{k}'" unless my_cols.include?(k.to_sym)
      attributes["#{k}".to_sym] = v
      
    end
    
  end

  def save
    @attributes.nil? || @attributes[:id].nil? ? self.insert : self.update
    
  end

  def update
    col_names_plus_qm = self.class.columns.join(" = ?, ") + " = ?"
    
    query = <<-SQL

    UPDATE
      #{self.class.table_name}
    SET
      #{col_names_plus_qm}
    WHERE
      id = ?
      
    SQL

    DBConnection.execute(query, *attribute_values, @attributes[:id])
  end

  def attribute_values
    self.class.columns.map { |col_name| @attributes[col_name] }
  end
end
