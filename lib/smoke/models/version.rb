module Smoke
  module Server
    class Version < ActiveRecord::Base
      belongs_to :asset
      
      def name
        ".#{self.asset.filename}.#{self.version_string}"
      end
      
      def path
        "#{self.asset.dir}#{name}"
      end

      def move_to_trash
        FileUtils.mv "#{self.asset.active_dir}#{name}", "#{self.asset.trash_dir}"
      end
      
    end
  end
end