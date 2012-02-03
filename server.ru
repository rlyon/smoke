require File.dirname(__FILE__) + '/config/initializers/smoke'
require File.dirname(__FILE__) + '/lib/smoke/smoke'

use Rack::Lint
use Smoke::S3::Auth
# Split up auth from path mangling for DNS style buckets
# HERE

run Smoke::S3::App