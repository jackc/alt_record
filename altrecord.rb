require 'rubygems'
require 'pg'

module AltRecord
  class Base  
    class << self
      def establish_connection(options={})
        @@connection = PGconn.connect(options)
      end
      
      def connection
        @@connection
      end
    
      def set_table_name( _table_name )
        @table_name = _table_name
      end
      
      def table_name
        @table_name
      end
      
      def map_column( column_name, column_type )
        c = Column.new
        c.name = column_name
        c.type = column_type
        columns << c
        
        class_eval <<-END_EVAL
          def #{column_name}
            @attributes["#{column_name}"]
          end
          
          def #{column_name}=(v)
            @attributes["#{column_name}"] = v
          end
        END_EVAL
      end
      
      def columns
        @columns ||= []
      end
            
      def find( id )
        pg_result = connection.exec( "SELECT #{@columns.map { |c| c.name }.join( ", " )} FROM #{table_name} WHERE id=$1", [ id.to_s ] )
        r = new
        r.instance_eval { @new_record = false }
        @columns.each do |c|
          r.send("#{c.name}=", c.cast_value(pg_result[0][c.name]))
        end
        r
      end
      
      def all
        ds = DataSet.new
        rows = connection.exec( "SELECT #{@columns.map { |c| c.name }.join( ", " )} FROM #{table_name}" )
        rows.each do |r|        
          ds.records.push( ds, r )
        end
        
        ds
      end
      
      def find_for_data_set(conditions)
        sql = "SELECT #{@columns.map { |c| c.name }.join( ", " )} FROM #{table_name}"
        params = []
        unless conditions.empty?
          where_sql = conditions.map { |c| c.sql }.join( " AND " )
          n = 0
          where_sql.gsub!("?") do
            n += 1
            "$#{n}"
          end
          conditions.each { |c| params += c.params }
          sql << " WHERE #{where_sql}"
        end
        pg_result = connection.exec( sql, params )
        pg_result.map do |row|
          r = new
          r.instance_eval { @new_record = false }
          @columns.each do |c|
            r.send("#{c.name}=", c.cast_value(row[c.name]))
          end
          r  
        end
      end
      
      def where( *args )
        ds = DataSet.new(self)
        sql = args.shift
        ds.add_condition(SqlCondition.new(sql, args))
        ds
      end
    end
    

    def initialize
      @attributes = {}
      @new_record = true
    end
    
    def new_record?
      @new_record
    end
    
    def attributes=(hash)
      hash.each do |k,v|
        send("#{k}=", v)
      end
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
        pg_result = self.class.connection.exec sql, columns.map { |c| send(c.name) }
		
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
  
  class SqlCondition
    attr_reader :sql
    attr_reader :params
    
    def initialize( _sql, _params )
      @sql = _sql
      @params = _params
    end
    
  end
  
  class DataSet
    def initialize( _model_class )
      @model_class = _model_class
      @conditions = []
      @records = nil
    end
    
    def add_condition(c)
      @conditions.push(c)
    end
    
    def where( *args )
      new_ds = @model_class.where(*args)
      @conditions.each { |c| new_ds.add_condition(c) }
      new_ds
    end
    
    def reload
      @records = nil
      all
    end
    
    def all
      @records ||= @model_class.find_for_data_set( @conditions )
    end
    
  end
end

AltRecord::Base.establish_connection :host => 'localhost', :dbname => 'Jack', :user => 'Jack', :password => 'Jack'

class Person < AltRecord::Base
  set_table_name "people"
  
  map_column 'id', :serial
  map_column 'last_name', :string
  map_column 'first_name', :string
  map_column 'age', :integer
end

p = Person.find 1
puts p.inspect