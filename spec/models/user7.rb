class User7< ActiveRecord::Base
  acts_as_test_friendly

  attr_accessor :first_name, :last_name

  test_friendly_validations do
    validates_presence_of :first_name, :last_name
  end

end
