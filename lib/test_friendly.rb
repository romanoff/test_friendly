module TestFriendly
  def acts_as_test_friendly
    @test_friendly = true
  end

  def test_friendly?
    !!@test_friendly
  end
end

if defined?(ActiveRecord::Base)
  ActiveRecord::Base.extend TestFriendly
end
