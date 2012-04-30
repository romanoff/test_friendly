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

class Rails
  def self.env
    'test'
  end
end

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
    require 'models/user1'
    user = User1.new
    user.should be_valid
  end

  it "should be able to turn validations on" do
    require 'models/user2'
    User2.force_validations
    user = User2.new
    user.should_not be_valid
    user.first_name = 'First name'
    user.last_name = 'Last name'
    user.should be_valid
  end

  it "should be able to drop validations" do
    Rails.stub(:env => 'development')
    require 'models/user3'
    user = User3.new
    user.should_not be_valid
    User3.drop_validations
    user.should be_valid
    User3.force_validations
    user.should_not be_valid
  end

  it "should be able to turn on validations using tag" do
    require 'models/user4'
    User4.force_validations(:additional)
    user = User4.new
    user.new_attribute = 'some value'
    user.should be_valid
    User4.force_validations
    user.should_not be_valid
  end

  it "should be able to drop validations using tag" do
    Rails.stub(:env => 'development')
    require 'models/user5'
    user = User5.new
    user.first_name = 'Vasja'
    user.last_name = 'Pupkin'
    user.should_not be_valid
    User5.drop_validations(:additional)
    user.should be_valid
  end

  it "should be able to drop and recover all validations" do
    Rails.stub(:env => 'development')
    require 'models/user6'
    User6.drop_validations(:all)
    user = User6.new
    user.should be_valid
    User6.force_validations(:all)
    user.first_name = 'first_name'
    user.last_name = 'last_name'
    user.should_not be_valid
    user.new_attribute = 'some attribute'
    user.should be_valid
  end
  
  it "should not add number of callbacks if validations were forced 2 times" do
    Rails.stub(:env => 'development')
    require 'models/user7'
    User7.force_validations
    User7.force_validations
    User7._validate_callbacks.length == 1
  end

  it "should be able to add different validations using same tag" do
    Rails.stub(:env => 'development')
    require 'models/user8'
    User8._validate_callbacks.length == 2
    User8.drop_validations(:additional)
    User8._validate_callbacks.length == 0
    User8.force_validations(:additional)
    User8._validate_callbacks.length == 2
  end

  it "should be able to force and drop all validations for all models" do
    Rails.stub(:env => 'development')
    require 'models/user9'
    require 'models/user10'
    user1 = User9.new
    user2 = User10.new
    user1.should_not be_valid
    user2.should_not be_valid
    TestFriendly::Global.drop_validations(:all)
    user1.should be_valid
    user2.should be_valid
    TestFriendly::Global.force_validations(:all)
    user1.should_not be_valid
    user2.should_not be_valid
  end
  
end
