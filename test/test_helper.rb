ENV["RAILS_ENV"] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/great_expectations'
require 'shoulda/context' # Thoughtbot context in tests
require 'auth_for_test'

# Improved Minitest output (color and progress bar)
#require "minitest/reporters"
#Minitest::Reporters.use!(
#  Minitest::Reporters::ProgressReporter.new,
#  ENV,
#  Minitest.backtrace_filter)

# FactoryBot
class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods
end

# Faker Unique
module FakerUniqueReset
  def after_teardown
    super
    Faker::UniqueGenerator.clear
  end
end

class Minitest::Test
  include FakerUniqueReset
end

class ActionDispatch::IntegrationTest
  include AuthForTest::Request
end

class ActionController::TestCase
  include AuthForTest::Controller
end
