module Sinatra
  module FetchHelper
    def setup(args = {})
      @user = user
      @buckets = user.buckets(:use_cache => false)
      if args.has_key?(:bucket)
        @bucket = bucket(args[:bucket])
      end
      
      if args.has_key?(:object)
        @object = object(args[:object])
      end
    end
    
    def user
      request.env['smoke.user']
    end
    
    def bucket(name)
      bucket = Smoke::SmBucket.find_by_name(name)  
      respond_error(:NoSuchBucket) if bucket.nil?
      respond_error(:AccessDenied) unless user.has_permission_to? :read, bucket
      log_access(:GET, user, bucket)
      bucket
    end
    
    def object(path)
      object = Smoke::SmObject.find(:object_key => path)
      respond_error(:NoSuchKey) if object.nil?
      respond_error(:AccessDenied) unless user.has_permission_to? :read, object
      object
    end
    
    def allow_params(*args)
      all_params = ['splat', 'captures'] + args
      respond_error(:InvalidArgument) unless params.include_only?(*all_params)
    end
    
    def require_acl(acl, obj)
      respond_error(:AccessDenied) unless user.has_permission_to? acl, obj
    end
    
  end
end