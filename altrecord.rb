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
  
  class Table
    def initialize( database, table_name )
      @database = database
      @table_name = table_name
      @columns = []
    end
    
    def map_column( column_name )
      c = Column.new
      c.name = column_name
      @columns << c
      
    end
    
    def find( id )
      @database.exec( "SELECT #{@columns.map { |c| c.name }.join( ", " )} FROM #{@table_name} WHERE id=$1", [ id.to_s ] )
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
  
  class Column
    attr_accessor :name
  end
  
  class Record
    attr_reader :data_set
    attr_reader :attributes
    
    def initialize( _data_set, _attributes )
      @data_set = _data_set
      @attributes = attributes.clone    
    end
  end
  
  class DataSet
    attr_reader :records
    
    def initialize
      @records = []
    end
  end
end

DB = AltRecord::Database.new :host => 'localhost', :dbname => 'Jack', :user => 'Jack', :password => 'Jack'

Person = AltRecord::Table.new DB, "people"
Person.map_column "id"
Person.map_column "last_name"
Person.map_column "first_name"

#results = DB.exec "select *, 1.2346549846456165465::float8 from people"

results = Person.find 1

p results.fsize(0)
p results.fsize(1)
p results.fsize(2)

results.each do |r|
  p r
  p r["float8"].to_f
end

p Person.all