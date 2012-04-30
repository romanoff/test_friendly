require 'active_model'
require 'active_support'

class ActiveRecord
  class Base;
    include ::ActiveModel::Validations
    include ::ActiveSupport::Callbacks
    define_callbacks :save
  end
end

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class User
  extend TestFriendly
end

class Person < ActiveRecord::Base
end

class Rails;end

describe "TestFriendly" do
  
  it "should be able to enable acts_as_test_friendly ability" do
    User.should_not be_test_friendly    
    User.acts_as_test_friendly
    User.should be_test_friendly
  end

  it "should be included in ActiveRecord::Base if it's present" do
    Person.acts_as_test_friendly
    Person.should be_test_friendly
  end

  it "should be not adding validations if Rails.env is test" do
    Rails.stub(:env => 'test')
    require 'models/user1'
    user = User1.new
    user.should be_valid
  end
  
end
