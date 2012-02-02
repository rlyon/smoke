module Smoke
  module Plugins
    module Permissions
      
      def self.included(klass)
        # There has got to be a better way than instansiating an object every time for testing
        raise "[Permissions]: Object #{klass.to_s} does not respond to id" unless klass.new.respond_to?(:id)
      end
      
      def allow(user, acl)
        acl = Acl.new(:user_id => user.id, :obj_id => self.id, :permission => acl.to_s)
        acl.save
      end
      
      def acls(args = {})
        args.include_only(:refresh)
        if args.include?(:refresh)
          @acls = Acl.where(:obj_id => self.id)
        else
          @acls = Acl.where(:obj_id => self.id)
        end
        @acls
      end
      
      def acl_all_values
        [:full_control, :read, :write, :read_acl, :write_acl ]
      end
      
      def acl_inherited_values(acl)
        if acl == :full_control
          return acl_all_values
        elsif acl == :write
          return [:read, :write]
        elsif acl == :write_acl
          return [:read_acl, :write_acl]
        end
        [acl]
      end
      
      def clear
        Acl.remove( :obj_id => self.id )
      end
      
      def permissions(user)
        return acl_all_values if self.user_id == user.id
        acl_list = Acl.where(:obj_id => self.id, :user_id => user.id)
        if acl_list.empty?
          # if the bucket has assets in it that we have permission to give read only access
          # return [:read]
          return [] if acl_list.empty?
        else
          acls = acl_list.map { |acl| acl.permission.to_sym }
          inherit = acls | acls.inject([]) { |arr,acl| arr | self.acl_inherited_values(acl) }
          inherit
        end
      end
    
    end
  end
end