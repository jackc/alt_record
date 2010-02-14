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
      
      def map_column( column_name )
        c = Column.new
        c.name = column_name
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
        @columns.each do |c|
          r.send("#{c.name}=", pg_result[0][c.name])
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
        sql = "INSERT INTO #{self.class.table_name} ("
        sql << self.class.columns.map { |c| c.name }.join(", ")
        sql << ") VALUES ("
        sql << (1..self.class.columns.size).map { |n| "$#{n}" }.join(", ")
        sql << ")"
        self.class.database.exec sql, self.class.columns.map { |c| send(c.name) }
      else
      
      end
    end
	end
  
  class Column
    attr_accessor :name
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
  
  map_column "id"
  map_column "last_name"
  map_column "first_name"
end

p = Person.new
p.id = 2
p.last_name = "Smith"
p.first_name = "John"
p.save