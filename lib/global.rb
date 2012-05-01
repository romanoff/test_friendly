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

    def self.drop_callbacks(tag = :defaults)
      @models ||= []
      @models.each do |model|
        model.drop_callbacks(tag)
      end      
    end

    def self.callbacks_on?
      Rails.env != 'test'
    end
  end

end
