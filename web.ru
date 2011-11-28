require File.dirname(__FILE__) + '/lib/smoke/helpers/session'
require File.dirname(__FILE__) + '/config/environment/web'
require File.dirname(__FILE__) + '/lib/smoke/web'

use Rack::Lint
run Smoke::Web::App