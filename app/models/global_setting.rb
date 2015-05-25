class GlobalSetting < ActiveRecord::Base
  enum datatype: [:string, :integer, :float, :boolean]

  validates_presence_of :key, :datatype
  validates :key, uniqueness: true

  after_commit :invalidate_cache

  def value
    send(datatype.to_sym)
  end

  def value=(value)
    self.datatype = datatype_from_object(value)
    send("#{datatype}=".to_sym, value)
    self.value
  end

  protected

  def datatype_from_object(object)
    GLOBAL_SETTING_DATATYPES[object.class.to_s] || 'string'
  end

  def invalidate_cache
    Rails.cache.delete "globalsetting/#{key}"
  end

  class << self
    def set(key, value)
      setting = find_or_create_by(key: key)
      setting.value = value
      setting.save!
      setting
    end

    def get(key)
      Rails.cache.fetch "globalsetting/#{key}" do
        setting = find_by(key: key)
        setting.nil? ? nil : setting.value
      end
    end

    def unset(key)
      setting = find_by(key: key)
      setting.nil? ? false : setting.destroy
    end
  end
end
