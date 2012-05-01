require 'global'
require 'test_friendly_helper'

module TestFriendly

  ModelCallback = Struct.new(:callback, :hash, :runner_symbol, :type)

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

  def force_callbacks(tag = :defaults, type = CALLBACK)
    callbacks_added = execute_callback_blocks(tag, type)
    helper = TestFriendlyHelper.get_helper_for(tag, type)
    if tag == :all || (!callbacks_added && !helper.tagged_callbacks.empty?)
      hashes = callbacks_hashes
      used_runners = []
      @model_callbacks.each do |model_callback|
        if !hashes.include?(model_callback.hash) && 
            ((tag == :all && model_callback.type == type) || helper.tagged_callbacks.include?(model_callback.hash))
          if !used_runners.include?(model_callback.runner_symbol)
            used_runners << model_callback.runner_symbol 
          end
          self.send("_#{model_callback.runner_symbol}_callbacks").push(model_callback.callback)
        end
      end
      used_runners.each do |runner_symbol|
        self.__define_runner(runner_symbol)
      end
    end
  end

  def drop_callbacks(tag = :defaults, type = CALLBACK)
    helper = TestFriendlyHelper.get_helper_for(tag, type)    
    used_runners = []
    @runner_symbols.each do |runner_symbol|
      self.send("_#{runner_symbol}_callbacks").reject! { |callback|
        model_callback = @model_callbacks.find{|mc| mc.hash == callback.hash}
        value = ((tag == :all && model_callback && model_callback.type == type) || 
                 helper.tagged_callbacks.include?(callback.hash))
        if value && !used_runners.include?(runner_symbol)
          used_runners << runner_symbol
        end
        value
      }
    end
    used_runners.each do |runner_symbol|
      self.__define_runner(runner_symbol)
    end    
  end

  def force_validations(tag = :defaults)
    force_callbacks(tag, VALIDATION)
  end

  def drop_validations(tag = :defaults)
    drop_callbacks(tag, VALIDATION)
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
    add_model_callbacks(type)
    helper.unprocessed_procs = []
  end

  def callbacks_hashes
    hashes = []
    @runner_symbols.each do |runner_symbol|
      hashes << self.send("_#{runner_symbol}_callbacks").map(&:hash)
    end
    hashes.flatten
  end

  def add_model_callbacks(type)
    callbacks_hashes = @model_callbacks.map(&:hash)
    @runner_symbols.each do |runner_symbol|
      callbacks = self.send("_#{runner_symbol}_callbacks")
      callbacks.each do |callback|
        if !callbacks_hashes.include?(callback.hash)
          @model_callbacks << ModelCallback.new(callback, callback.hash, runner_symbol, type) 
        end
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
