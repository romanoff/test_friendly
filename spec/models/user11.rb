class User11 < ActiveRecord::Base
  acts_as_test_friendly

  attr_accessor :executed_actions
  
  test_friendly_callbacks do
    set_callback :save, :before do |object|
      object.set_executed('before_save')
    end
    set_callback :save, :after do |object|
      object.set_executed('after_save')
    end
  end

  def save
    run_callbacks :save do
      set_executed('save')
    end
  end

  def set_executed(action)
    @executed_actions ||= []
    @executed_actions << action
  end

end
