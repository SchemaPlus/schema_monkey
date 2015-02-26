module SchemaMonkey

  # The main manager for the monkey patches.  Singleton instance
  # created by SchemaMonkey.monkey

  class Monkey

    attr_reader :clients, :stacks

    def initialize
      @clients = []
      @inserted = nil
      @inserted_dbm = nil
      Module.insert ::ActiveRecord::ConnectionAdapters::AbstractAdapter, SchemaMonkey::ActiveRecord::ConnectionAdapters::AbstractAdapter
    end

    def register(mod)
      client = Client.new(mod)
      clients << client
      client.insert if @inserted
      client.insert(dbm: @inserted_dbm) if @inserted_dbm
    end

    def insert(dbm: nil)
      insert if dbm and not @inserted # first do all non-dbm-specific insertions
      clients.each &it.insert(dbm: dbm)
      @inserted = true
      @inserted_dbm = dbm if dbm
    end

  end
end
