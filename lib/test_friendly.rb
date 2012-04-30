module TestFriendly
  def acts_as_test_friendly
    @test_friendly = true
    @model_callbacks = []
  end

  def test_friendly?
    !!@test_friendly
  end

  def test_friendly_validations(&block)
    @validations_block = block
    if callbacks_on?
      @validations_block.call
      @model_callbacks << self._validate_callbacks
      @model_callbacks.flatten!
      @model_callbacks.uniq!
      @validations_block = nil
    end
  end

  def callbacks_on?
    Rails.env != 'test'
  end

  def force_validations
    if @validations_block
      @validations_block.call
      @model_callbacks << self._validate_callbacks
      @model_callbacks.flatten!
      @model_callbacks.uniq!
      @validations_block = nil
    elsif @model_callbacks.length > 0 && self._validate_callbacks.length == 0
      @model_callbacks.each do |callback|
        self._validate_callbacks << callback
      end
      self.__define_runner(:validate)      
    end
  end

  def drop_validations
    self._validate_callbacks.reject!{true}
    self.__define_runner(:validate)
  end

end

if defined?(ActiveRecord::Base)
  ActiveRecord::Base.extend TestFriendly
end
