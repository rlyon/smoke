require File.dirname(__FILE__) + '/spec_helper'

describe "App" do
  include Rack::Test::Methods

  def app
    @app ||= Smoke::Web::App.new
  end

  it "should respond to /" do
    get '/'
    last_response.should be_ok
  end
  
  it "should display index when not logged in" do
    get '/'
    last_response.should be_ok
    last_response.body.should include('<h1>Home</h1>')
  end
end