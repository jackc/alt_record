require 'rubygems'
require 'pg'

module AltRecord
  class Database
 
    # Connection options
    def initialize(options={})
      @connection = PGconn.connect(options)
    end
  
    def exec( sql, params=nil )
      @connection.exec sql, params
    end
  
  end
  
  module Base
    def self.included(other)
      other.extend( ClassMethods )
      other.instance_eval do
        @database = AltRecord::Database.new :host => 'localhost', :dbname => 'Jack', :user => 'Jack', :password => 'Jack'
        @table_name = ""
        @columns = []
      end
    end
    
 
    module ClassMethods
      def set_table_name( _table_name )
        @table_name = _table_name
      end
      
      def table_name
        @table_name
      end
      
      def database
        @database
      end
      
      def map_column( column_name, column_type )
        c = Column.new
        c.name = column_name
        c.type = column_type
        @columns << c
        
        class_eval <<-END_EVAL
          def #{column_name}
            @ar_#{column_name}
          end
          
          def #{column_name}=(v)
            @ar_#{column_name} = v
          end
        END_EVAL
      end
      
      def columns
        @columns
      end
            
      def find( id )
        pg_result = @database.exec( "SELECT #{@columns.map { |c| c.name }.join( ", " )} FROM #{@table_name} WHERE id=$1", [ id.to_s ] )
        r = new
        r.instance_eval { @new_record = false }
        @columns.each do |c|
          r.send("#{c.name}=", c.cast_value(pg_result[0][c.name]))
        end
        r
      end
      
      def all
        ds = DataSet.new
        rows = @database.exec( "SELECT #{@columns.map { |c| c.name }.join( ", " )} FROM #{@table_name}" )
        rows.each do |r|        
          ds.records.push( ds, r )
        end
        
        ds
      end
    end
    
    def initialize
      @new_record = true
    end
    
    def new_record?
      @new_record
    end
    
    def save
      if new_record?
        columns = self.class.columns.reject { |c| c.type == :serial }
        returning_columns = self.class.columns.select { |c| c.type == :serial }
        sql = "INSERT INTO #{self.class.table_name} ("
        sql << columns.map { |c| c.name }.join(", ")
        sql << ") VALUES ("
        sql << (1..columns.size).map { |n| "$#{n}" }.join(", ")
        sql << ")"
        sql << " RETURNING #{returning_columns.map { |c| c.name }.join( ', ')}" unless returning_columns.empty?
        pg_result = self.class.database.exec sql, columns.map { |c| send(c.name) }
		
        @new_record = false
        returning_columns.each_with_index do |c,i|
          send("#{c.name}=", pg_result.getvalue(0,i))
        end
      else
      
      end
    end
	end
  
  class Column
    attr_accessor :name
    attr_accessor :type
	
    def cast_value(v)
      case type
      when :string
        v.to_s
      when :integer
        Integer(v)
      else
        v
      end
    end
  end
  
  class DataSet
    attr_reader :records
    
    def initialize
      @records = []
    end
  end
end

class Person
  include AltRecord::Base
  
  set_table_name "people"
  
  map_column 'id', :serial
  map_column 'last_name', :string
  map_column 'first_name', :string
  map_column 'age', :integer
end

p = Person.find 1
puts p.inspect