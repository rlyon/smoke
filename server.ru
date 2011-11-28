require File.dirname(__FILE__) + '/config/environment/server'
require File.dirname(__FILE__) + '/lib/smoke/server'

use Rack::Lint
use Smoke::Server::Auth
# Split up auth from path mangling for DNS style buckets
# HERE

run Smoke::Server::App