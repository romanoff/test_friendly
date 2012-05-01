require 'global'
require 'test_friendly_helper'

module TestFriendly

  VALIDATION = 1
  CALLBACK = 2

  def __define_runner(symbol)
    @runner_symbols << symbol unless @runner_symbols.include?(symbol)
    super(symbol)
  end

  def acts_as_test_friendly
    @test_friendly = true
    @model_callbacks = []
    @runner_symbols = []
    Global.add_model(self)
  end

  def test_friendly?
    !!@test_friendly
  end

  def test_friendly_validations(tag = :defaults, &block)
    helper = TestFriendlyHelper.get_helper_for(tag, VALIDATION)
    helper.unprocessed_procs << block
    if Global.callbacks_on?
      execute_callback_blocks(tag, VALIDATION)
    end
  end

  def force_validations(tag = :defaults)
    callbacks_added = execute_callback_blocks(tag, VALIDATION)
    helper = TestFriendlyHelper.get_helper_for(tag, VALIDATION)
    if self.respond_to?(:_validate_callbacks) && 
        (tag == :all || !callbacks_added && !helper.tagged_callbacks.empty?)
      used_callbacks_hashes = self._validate_callbacks.map(&:hash)
      @model_callbacks.each do |callback|
        if !used_callbacks_hashes.include?(callback.hash) && 
            (tag == :all || helper.tagged_callbacks.include?(callback.hash))
          self._validate_callbacks << callback
        end
      end
      self.__define_runner(:validate)      
    end
  end

  def drop_validations(tag = :defaults)
    helper = TestFriendlyHelper.get_helper_for(tag, VALIDATION)    
    if self.respond_to?(:_validate_callbacks)
      self._validate_callbacks.reject!{ |callback|
        tag == :all || helper.tagged_callbacks.include?(callback.hash)
      }
      self.__define_runner(:validate)
    end
  end

  private

  def execute_callback_blocks(tag, type)
    helper = TestFriendlyHelper.get_helper_for(tag, type)
    return false if helper.unprocessed_procs.empty?
    before = callbacks_hashes
    helper.unprocessed_procs.each do |proc|
      proc.call
    end
    after = callbacks_hashes
    diff = after - before
    helper.tagged_callbacks << diff
    helper.optimize_tagged_callbacks
    add_model_callbacks
    helper.unprocessed_procs = []
  end

  def callbacks_hashes
    hashes = []
    @runner_symbols.each do |runner_symbol|
      hashes << self.send("_#{runner_symbol}_callbacks").map(&:hash)
    end
    hashes.flatten
  end

  def add_model_callbacks
    callbacks_hashes = @model_callbacks.map(&:hash)
    @runner_symbols.each do |runner_symbol|
      callbacks = self.send("_#{runner_symbol}_callbacks")
      callbacks.each do |callback|
        @model_callbacks << callback unless callbacks_hashes.include?(callback.hash)
      end
    end
  end

end

if defined?(ActiveRecord::Base)
  ActiveRecord::Base.extend TestFriendly
end

if defined?(RSpec) && !TestFriendly::Global.callbacks_on?
  RSpec.configure do |config|
    config.before(:each) do
      TestFriendly::Global.drop_validations(:all)
    end
  end
end
