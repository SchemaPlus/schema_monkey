module SchemaMonkey

  # The main manager for the monkey patches.  Singleton instance 
  # created by SchemaMonkey.monkey

  class Monkey

    attr_reader :clients, :stacks

    def initialize
      @clients = []
      @inserted = nil
      @inserted_dbm = nil
    end

    def register(mod)
      client = Client.new(mod)
      clients << client
      client.insert if @inserted
      client.insert(@inserted_dbm) if @inserted_dbm
    end

    def insert(dbm: nil)
      @inserted = true
      @inserted_dbm = dbm if dbm
      clients.each &it.insert(dbm: dbm)
    end

  end
end
