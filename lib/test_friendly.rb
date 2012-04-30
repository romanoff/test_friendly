module TestFriendly
  def acts_as_test_friendly
    @test_friendly = true
  end

  def test_friendly?
    !!@test_friendly
  end

  def test_friendly_validations(*block_names, &block)
    block.call if callbacks_on?
  end

  def callbacks_on?
    Rails.env != 'test'
  end

end

if defined?(ActiveRecord::Base)
  ActiveRecord::Base.extend TestFriendly
end
