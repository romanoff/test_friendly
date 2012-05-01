class TestFriendlyHelper

  attr_accessor :unprocessed_procs, :tagged_callbacks

  def initialize
    @unprocessed_procs = []
    @tagged_callbacks = []
  end

  def optimize_tagged_callbacks
    @tagged_callbacks.flatten!
    @tagged_callbacks.uniq!
  end

  def self.get_helper_for(tag, type)
    @helpers ||= {}
    @helpers[type] ||= {}
    if !@helpers[type][tag]
      @helpers[type][tag] = TestFriendlyHelper.new
    end
    @helpers[type][tag]
  end

end
