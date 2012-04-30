module TestFriendly
  class Global
    def self.add_model(model)
      @models ||= []
      @models << model
      @models.uniq!
    end

    def self.force_validations(tag = :defaults)
      @models ||= []      
      @models.each do |model|
        model.force_validations(tag)
      end
    end
    
    def self.drop_validations(tag = :defaults)
      @models ||= []
      @models.each do |model|
        model.drop_validations(tag)
      end
    end

    def self.callbacks_on?
      Rails.env != 'test'
    end
  end

  def acts_as_test_friendly
    @test_friendly = true
    @model_callbacks = []
    @tagged_callbacks = {}
    @unprocessed_procs = {}
    Global.add_model(self)
  end

  def test_friendly?
    !!@test_friendly
  end

  def test_friendly_validations(tag = :defaults, &block)
    @unprocessed_procs[tag] ||= []
    @unprocessed_procs[tag] << block
    if Global.callbacks_on?
      execute_callback_blocks(tag)
    end
  end

  def force_validations(tag = :defaults)
    callbacks_added = execute_callback_blocks(tag)
    @tagged_callbacks[tag] ||= []
    if self.respond_to?(:_validate_callbacks) && 
        (tag == :all || !callbacks_added && !@tagged_callbacks[tag].empty?)
      used_callbacks_hashes = self._validate_callbacks.map(&:hash)
      @model_callbacks.each do |callback|
        if !used_callbacks_hashes.include?(callback.hash) && 
            (tag == :all || @tagged_callbacks[tag].include?(callback.hash))
          self._validate_callbacks << callback
        end
      end
      self.__define_runner(:validate)      
    end
  end

  def drop_validations(tag = :defaults)
    @tagged_callbacks[tag] ||= [] if tag != :all
    if self.respond_to?(:_validate_callbacks)
      self._validate_callbacks.reject!{ |callback|
        tag == :all || @tagged_callbacks[tag].include?(callback.hash)
      }
      self.__define_runner(:validate)
    end
  end

  private

  def execute_callback_blocks(tag)
    @unprocessed_procs[tag] ||= []
    return false if @unprocessed_procs[tag].empty?
    before = self._validate_callbacks.map(&:hash)
    @unprocessed_procs[tag].each do |proc|
      proc.call
    end
    after = self._validate_callbacks.map(&:hash)
    diff = after - before
    @tagged_callbacks[tag] ||= []
    @tagged_callbacks[tag] << diff
    @tagged_callbacks[tag].flatten!
    @tagged_callbacks[tag].uniq!
    @model_callbacks << self._validate_callbacks
    @model_callbacks.flatten!
    @model_callbacks.uniq!
    @unprocessed_procs[tag] = []
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
