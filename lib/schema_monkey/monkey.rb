module SchemaMonkey

  # The main manager for the monkey patches.  Singleton instance
  # created by SchemaMonkey.monkey

  class Monkey

    def initialize
      @client_map = {}
      @inserted = nil
      @inserted_dbm = nil
      Module.insert ::ActiveRecord::ConnectionAdapters::AbstractAdapter, SchemaMonkey::ActiveRecord::ConnectionAdapters::AbstractAdapter
    end

    def register(mod)
      @client_map[mod] ||= Client.new(mod).tap { |client|
        client.insert if @inserted
        client.insert(dbm: @inserted_dbm) if @inserted_dbm
      }
    end

    def insert(dbm: nil)
      insert if dbm and not @inserted # first do all non-dbm-specific insertions
      @client_map.values.each &it.insert(dbm: dbm)
      @inserted = true
      @inserted_dbm = dbm if dbm
    end

  end
end
