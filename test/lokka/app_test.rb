require File.dirname(__FILE__) + '/../test_helper'
require 'lokka'
require 'lokka/app'

class AppTest < Test::Unit::TestCase
  context "Access pages" do
    should "show index" do
      get '/'
      assert_match 'Test Site', last_response.body
    end

    should "show individual" do
      get '/1'
      assert_match 'Test Site', last_response.body
    end
  end
end
