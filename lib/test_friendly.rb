module TestFriendly
  def acts_as_test_friendly
    @test_friendly = true
  end

  def test_friendly?
    !!@test_friendly
  end

  def test_friendly_validations(&block)
    @validations_block = block
    if callbacks_on?
      @validations_block.call
      @validations_block = nil
    end
  end

  def callbacks_on?
    Rails.env != 'test'
  end

  def force_validations
    if @validations_block
      @validations_block.call
      @validations_block = nil
    end
  end

end

if defined?(ActiveRecord::Base)
  ActiveRecord::Base.extend TestFriendly
end
