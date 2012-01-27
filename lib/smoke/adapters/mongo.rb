module Smoke
  module Connection
    def connection
      @@connection ||= Mongo::Connection.new
    end
    
    def database=(name)
      @@database = nil
      @@database_name = name
    end
    
    def database
      begin
        @@database ||= Smoke.connection.db(@@database_name)
      rescue NameError
        raise "You need to set the database name: Smoke.database = foo"
      end
    end
    
    def collection(name)
      @collection ||= Smoke.database.collection(name)
    end
  end
end
