module TestFriendly
  def acts_as_test_friendly
    @test_friendly = true
    @model_callbacks = []
    @tagged_callbacks = {}
    @unprocessed_procs = {}
  end

  def test_friendly?
    !!@test_friendly
  end

  def test_friendly_validations(tag = :defaults, &block)
    @unprocessed_procs[tag] ||= []
    @unprocessed_procs[tag] << block
    if callbacks_on?
      execute_callback_blocks(tag)
    end
  end

  def callbacks_on?
    Rails.env != 'test'
  end

  def force_validations(tag = :defaults)
    callbacks_added = execute_callback_blocks(tag)
    @tagged_callbacks[tag] ||= []
    if tag == :all || !callbacks_added && !@tagged_callbacks[tag].empty?
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
    self._validate_callbacks.reject!{ |callback|
      tag == :all || @tagged_callbacks[tag].include?(callback.hash)
    }
    self.__define_runner(:validate)
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
