module Smoke
  module Plugins
    module Permissions
      
      def self.included(klass)
        raise "[Permissions]: Object does not respond to id" unless klass.respond_to?(:id)
      end
      
      def acl_for(user, *acls)
        acl = Acl.new(:user_id => user.id, :obj_id => self.id)
        acl.permissions = acls
        acl.save
      end
      
      def acls(*args)
        args.include_only(:refresh)
        # Use a special all method which gets shared buckets as well
        if args.include?(:refresh)
          @acls = Acl.where(:obj_id => self.id)
        else
          @acls ||= Acl.where(:obj_id => self.id)
        end
        @acls
      end
      
      def acl_all_values
        [:full_control, :read, :write, :read_acl, :write_acl ]
      end
      
      def add(acl)
        
        Acl.new( :obj_id => self.id, :user_id => user.id, :permission => acl.to_s )
      end
      
      def clear
        Acl.remove( :obj_id => self.id )
      end
      
      def permissions(user)
        return  if self.user_id == user.id
        acl_list = Acl.where(:obj_id => self.id, :user_id => user.id)
        if acl_list.empty?
          # if the bucket has assets in it that we have permission to give read only access
          # return [:read]
          return [] if acl_list.empty?
        else
          acl_list.map { |acl| acl.permission.to_sym }
        end
      end
    
    end
  end
end