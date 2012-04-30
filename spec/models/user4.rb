class User4< ActiveRecord::Base
  acts_as_test_friendly

  attr_accessor :first_name, :last_name, :new_attribute

  test_friendly_validations do
    validates_presence_of :first_name, :last_name
  end

  test_friendly_validations(:additional) do
    validates_presence_of :new_attribute
  end

end
