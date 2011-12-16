# Smoke - A rack/sinatra based S3 Server implementation

Smoke - looks like a cloud but really isn't one - aims to leverage existing cloud storage protocols that are widely used by companies such as Amazon (the author or S3), Rackspace and Eucalyptus and make these protocols available to access data stored in non-cloud based filesystems at local/private data centers.  By facilitating access to these non-cloud based filesystems, the proxy will reduce the overall complexity of accessing data locally and in the cloud, and will allow existing GUI and command line clients that understand the cloud based storage protocols to communicate with local storage systems as if the data was located in the cloud.

## Setup
	$ yum install -y gcc-c++ patch readline readline-devel zlib zlib-devel libyaml-devel libffi-devel openssl-devel \
	  make bzip2 autoconf automake libtool bison git nginx sqlite-devel libxml2-devel libxslt-devel curl-devel
	$ git clone git@github.com:rlyon/smoke.git
	$ cd smoke
	$ yum install 
	$ bundle install
	
Modify the configuration files for nginx, thin and smoke.  Examples are found in the config directory.
	
	$ rake db:create
	$ rake db:seed
	$ service nginx start
	$ SMOKE_ENV="production" thin -C config/thin.server.yml -e production start
	
## Requirements
 Ruby 1.9.2
