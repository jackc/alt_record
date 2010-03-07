require 'rubygems'
require 'pg'

require 'alt_record/column'
require 'alt_record/string_column'
require 'alt_record/integer_column'
require 'alt_record/serial_column'
require 'alt_record/date_column'

module AltRecord
  VERSION = '0.0.2'

  class LazyLoadedValue
  end

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
        c = case column_type
            when :serial
              SerialColumn.new(column_name, options)
            when :integer
              IntegerColumn.new(column_name, options)
            when :string
              StringColumn.new(column_name, options)
            when :date
              DateColumn.new(column_name, options)
            else
              raise ArgumentError, "Bad column type: #{column_type}"
            end
        columns << c
        
        class_eval <<-END_EVAL
          def #{c.name}
            if @attributes["#{c.name}"] == LazyLoadedValue
              column = self.class.columns[#{columns.size-1}]
              self.class.lazy_load_column_values(column, data_set)
            end
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
            
      def find( *keys_and_options )
        options = keys_and_options.pop if keys_and_options.last.kind_of?(Hash)
        keys = keys_and_options
        
        sql_conditions = []
        primary_key_columns.each_with_index do |c,i|
          sql_conditions.push "#{c.name}=$#{i+1}"
        end
        sql = "SELECT #{columns_to_select(options).map { |c| c.name }.join( ", " )} FROM #{table_name} WHERE #{sql_conditions.join(' AND ')}"
        
        pg_result = connection.exec( sql, keys.map { |k| k.to_s } )
        from_postgresql_hash(pg_result[0])
      end
      
      def find_all(options={})
        pg_result = connection.exec( "SELECT #{columns_to_select(options).map { |c| c.name }.join( ", " )} FROM #{table_name}" )
        data_set = pg_result.map do |pg_hash|
          from_postgresql_hash(pg_hash)
        end
        data_set.each do |r|
          r.instance_eval { @data_set = data_set }
        end

        data_set
      end

      def columns_to_select(options={})
        columns.reject { |c| c.lazy }
      end

      def from_postgresql_hash(hash)
        record = new
        record.instance_eval { @new_record = false }
        @columns.each do |c|
          if hash.has_key?(c.name)
            record.send("#{c.name}=", c.cast_value(hash[c.name]))
          else
            record.send("#{c.name}=", LazyLoadedValue)
          end
        end
        record
      end

      def lazy_load_column_values(column, data_set)
        where_strings = []
        sql_params = []

        data_set.each do |record|
          s = []
          primary_key_columns.each do |c|
            s.push("#{c.name}=$#{sql_params.size+1}")
            sql_params.push(record.send(c.name))
          end
          where_strings.push( s.join(" AND ") )
        end

        where_sql = where_strings.map { |s| "(#{s})"}.join(" OR ")

        select_sql = primary_key_columns.map { |c| c.name }.join(", ")
        select_sql << ", #{column.name}"

        pg_result = connection.exec("SELECT #{select_sql} FROM #{table_name} WHERE #{where_sql}", sql_params)
        pg_result.each do |hash|
          record = data_set.detect do |r|
            primary_key_columns.all? do |c|
              r.send(c.name) == c.cast_value(hash[c.name])
            end
          end

          record.send("#{column.name}=", column.cast_value(hash[column.name]))
        end
      end
    end

    attr_reader :data_set

    def initialize(attributes=nil)
      @new_record = true
      @attributes = {}
      @data_set = nil
      self.attributes = attributes if attributes
    end
    
    def new_record?
      @new_record
    end

    def attributes
      @attributes
    end
    
    def attributes=(hash)
      hash.each do |k,v|
        send("#{k}=", v)
      end
    end
    
    def save
      if new_record?
        columns = self.class.columns.reject { |c| c.kind_of?(SerialColumn) }
        returning_columns = self.class.columns.select { |c| c.kind_of?(SerialColumn) }
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
  
  class SqlFilter
    attr_reader :sql
    attr_reader :params
    
    def initialize( _sql, *_params )
      @sql = _sql
      @params = _params
    end
    
    def ==(other)
      self.sql == other.sql && self.params == other.params
    end    
  end
end
