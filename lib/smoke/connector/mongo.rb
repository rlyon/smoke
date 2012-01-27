module Smoke
  module MongoConnector
    
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
    
  end
end
