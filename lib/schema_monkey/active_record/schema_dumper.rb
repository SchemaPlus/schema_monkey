require 'ostruct'
require 'tsort'

module SchemaMonkey
  module ActiveRecord
    module SchemaDumper

      class Dump
        include TSort

        attr_reader :extensions, :tables, :dependencies, :data
        attr_accessor :foreign_keys, :trailer

        def initialize(dumper)
          @dumper = dumper
          @dependencies = Hash.new { |h, k| h[k] = [] }
          @extensions = []
          @tables = {}
          @foreign_keys = []
          @data = OpenStruct.new # a place for middleware to leave data
        end

        def depends(tablename, dependents)
          @tables[tablename] ||= false # placeholder for dependencies applied before defining the table
          @dependencies[tablename] += Array.wrap(dependents)
        end

        def assemble(stream)
          stream.puts @extensions.join("\n") if extensions.any?
          assemble_tables(stream)
          foreign_keys.each do |statement|
            stream.puts "  #{statement}"
          end
          stream.puts @trailer
        end

        def assemble_tables(stream)
          tsort().each do |table|
            @tables[table].assemble(stream) if @tables[table]
          end
        end

        def tsort_each_node(&block)
          @tables.keys.sort.each(&block)
        end

        def tsort_each_child(tablename, &block)
          @dependencies[tablename].sort.uniq.reject{|t| @dumper.ignored? t}.each(&block)
        end

        class Table < KeyStruct[:name, :pname, :options, :columns, :indexes, :statements, :trailer]
          def initialize(*args)
            super
            self.columns ||= []
            self.indexes ||= []
            self.statements ||= []
            self.trailer ||= []
          end

          def assemble(stream)
            stream.write "  create_table #{pname.inspect}"
            stream.write ", #{options}" unless options.blank?
            stream.puts " do |t|"
            typelen = columns.map{|col| col.type.length}.max
            namelen = columns.map{|col| col.name.length}.max
            columns.each do |column|
              stream.write "    "
              column.assemble(stream, typelen, namelen)
              stream.puts ""
            end
            statements.each do |statement|
              stream.puts "    #{statement}"
            end
            stream.puts "  end"
            indexes.each do |index|
              stream.write "  add_index #{pname.inspect}, "
              index.assemble(stream)
              stream.puts ""
            end
            trailer.each do |statement|
              stream.puts "  #{statement}"
            end
            stream.puts ""
          end

          class Column < KeyStruct[:name, :type, :options, :comments]

            def add_option(option)
              self.options = [options, option].reject(&:blank?).join(', ')
            end

            def add_comment(comment)
              self.comments = [comments, comment].reject(&:blank?).join('; ')
            end

            def assemble(stream, typelen, namelen)
              stream.write "t.%-#{typelen}s " % type
              if options.blank? && comments.blank?
                stream.write name.inspect
              else
                pr = name.inspect
                pr += "," unless options.blank?
                stream.write "%-#{namelen+3}s " % pr
              end
              stream.write "#{options}" unless options.blank?
              stream.write " " unless options.blank? or comments.blank?
              stream.write "# #{comments}" unless comments.blank?
            end
          end

          class Index < KeyStruct[:name, :columns, :options]

            def add_option(option)
              self.options = [options, option].reject(&:blank?).join(', ')
            end

            def assemble(stream)
              stream.write [
                columns.inspect,
                "name: #{name.inspect}",
                options
              ].reject(&:blank?).join(", ")
            end
          end
        end
      end

      def self.included(base)
        base.class_eval do
          alias_method_chain :dump, :schema_monkey
          alias_method_chain :extensions, :schema_monkey
          alias_method_chain :tables, :schema_monkey
          alias_method_chain :table, :schema_monkey
          alias_method_chain :foreign_keys, :schema_monkey
          alias_method_chain :trailer, :schema_monkey
          alias_method_chain :indexes, :schema_monkey
          public :ignored?
        end
      end

      def dump_with_schema_monkey(stream)
        @dump = Dump.new(self)
        dump_without_schema_monkey(stream)
        @dump.assemble(stream)
      end

      def foreign_keys_with_schema_monkey(table, _)
        stream = StringIO.new
        foreign_keys_without_schema_monkey(table, stream)
        @dump.foreign_keys += stream.string.split("\n").map(&:strip)
      end

      def trailer_with_schema_monkey(_)
        stream = StringIO.new
        trailer_without_schema_monkey(stream)
        @dump.trailer = stream.string
      end

      def extensions_with_schema_monkey(_)
        Middleware::Dumper::Extensions.start dumper: self, connection: @connection, dump: @dump, extensions: @dump.extensions do |env|
          stream = StringIO.new
          extensions_without_schema_monkey(stream)
          env.dump.extensions << stream.string unless stream.string.blank?
        end
      end

      def tables_with_schema_monkey(_)
        Middleware::Dumper::Tables.start dumper: self, connection: @connection, dump: @dump do |env|
          tables_without_schema_monkey(nil)
        end
      end

      def table_with_schema_monkey(table, _)
        Middleware::Dumper::Table.start dumper: self, connection: @connection, dump: @dump, table: @dump.tables[table] = Dump::Table.new(name: table) do |env|
          stream = StringIO.new
          table_without_schema_monkey(env.table.name, stream)
          m = stream.string.match %r{
          \A \s*
            create_table \s*
            [:'"](?<name>[^'"\s]+)['"]? \s*
            ,? \s*
            (?<options>.*) \s+
            do \s* \|t\| \s* $
          (?<columns>.*)
          ^\s*end\s*$
          (?<trailer>.*)
          \Z
          }xm
          env.table.pname = m[:name]
          env.table.options = m[:options].strip
          env.table.trailer = m[:trailer].split("\n").map(&:strip).reject{|s| s.blank?}
          env.table.columns = m[:columns].strip.split("\n").map { |col|
            m = col.strip.match %r{
            ^
            t\.(?<type>\S+) \s*
              [:'"](?<name>[^"\s]+)[,"]? \s*
              ,? \s*
              (?<options>.*)
            $
            }x
            Dump::Table::Column.new(name: m[:name], type: m[:type], options: m[:options])
          }
        end
      end

      def indexes_with_schema_monkey(table, _)
        Middleware::Dumper::Indexes.start dumper: self, connection: @connection, dump: @dump, table: @dump.tables[table] do |env|
          stream = StringIO.new
          indexes_without_schema_monkey(env.table.name, stream)
          env.table.indexes += stream.string.split("\n").map { |string|
            m = string.strip.match %r{
              ^
              add_index \s*
              [:'"](?<table>[^'"\s]+)['"]? \s* , \s*
              (?<columns>.*) \s*
              name: \s* [:'"](?<name>[^'"\s]+)['"]? \s*
              (, \s* (?<options>.*))?
              $
            }x
            columns = m[:columns].tr(%q{[]'":}, '').strip.split(/\s*,\s*/)
            Dump::Table::Index.new name: m[:name], columns: columns, options: m[:options]
          }
        end
      end
    end
  end
end
