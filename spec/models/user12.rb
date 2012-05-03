class User12< ActiveRecord::Base

  attr_accessor :first_name, :last_name

  test_friendly_validations do
    validates_presence_of :first_name, :last_name
  end

end
