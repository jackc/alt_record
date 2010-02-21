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
      
      def map_column( column_name, column_type, options={} )
        c = Column.new(column_name, column_type, options)
        columns << c
        
        class_eval <<-END_EVAL
          def #{c.name}
            @attributes["#{c.name}"]
          end
          
          def #{c.name}=(v)
            @attributes["#{c.name}"] = v
          end
        END_EVAL
      end
      
      def columns
        @columns ||= []
      end
      
      def primary_key_columns
        columns.select { |c| c.primary_key? }
      end
            
      def find( *keys )
        sql_conditions = []
        primary_key_columns.each_with_index do |c,i|
          sql_conditions.push "#{c.name}=$#{i+1}"
        end
        sql = "SELECT #{@columns.map { |c| c.name }.join( ", " )} FROM #{table_name} WHERE #{sql_conditions.join(' AND ')}"
        
        pg_result = connection.exec( sql, keys.map { |k| k.to_s } )
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
      
      def find_for_data_set(filters)
        sql = "SELECT #{@columns.map { |c| c.name }.join( ", " )} FROM #{table_name}"
        params = []
        unless filters.empty?
          where_sql = filters.map { |c| c.sql }.join( " AND " )
          n = 0
          where_sql.gsub!("?") do
            n += 1
            "$#{n}"
          end
          filters.each { |c| params += c.params }
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
        ds.filters.push(SqlFilter.new(sql, args))
        ds
      end
    end
    

    def initialize(attributes=nil)
      @new_record = true
      @attributes = {}
      self.attributes = attributes if attributes
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
        pk_columns, non_pk_columns = self.class.columns.partition { |c| c.primary_key? }
        
        bind_var_num = 0
        
        set_clause = non_pk_columns.map do |c|
           bind_var_num += 1
          "#{c.name}=$#{bind_var_num}"
        end.join(", ")
        
        where_clause = pk_columns.map do |c|
          bind_var_num += 1
          "#{c.name}=$#{bind_var_num}"
        end.join(' AND ')
        
        sql = "UPDATE #{self.class.table_name} SET #{set_clause} WHERE #{where_clause}"
        self.class.connection.exec( sql, (non_pk_columns+pk_columns).map { |c| send(c.name).to_s } )
      end
    end
	end
  
  class Column
    attr_reader :name
    attr_reader :type
    
    def initialize(name, type, options={})
      @name = name
      @type = type
      @primary_key = type == :serial || options[:primary_key] 
    end
    
    def primary_key?
      @primary_key
    end
	
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
  
  class SqlFilter
    attr_reader :sql
    attr_reader :params
    
    def initialize( _sql, _params )
      @sql = _sql
      @params = _params
    end
    
  end
  
  class DataSet
    attr_reader :model_class
    attr_reader :filters

    def initialize( _model_class )
      @model_class = _model_class
      @filters = []
      @records = nil
    end
    
    def where( *args )
      new_ds = @model_class.where(*args)
      @filters.each { |c| new_ds.filters.push(c) }
      new_ds
    end
    
    def reload
      @records = nil
      all
    end
    
    def all
      @records ||= @model_class.find_for_data_set( @filters )
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