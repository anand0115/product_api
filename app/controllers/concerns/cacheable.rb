module Cacheable
  extend ActiveSupport::Concern

  CACHE_EXPIRY = 1.hour

  private

  def cache_fetch(key, expires_in: CACHE_EXPIRY, &block)
    Rails.cache.fetch(key, expires_in: expires_in, &block)
  end

  def collection_cache_key(model_class, page = nil)
    max_updated_at = model_class.maximum(:updated_at)&.utc&.to_fs(:usec)
    count = model_class.count
    "#{model_class.table_name}/all-#{count}-#{max_updated_at}-page-#{page || 'all'}"
  end

  def record_cache_key(record)
    "#{record.class.table_name}/#{record.id}-#{record.updated_at.to_i}"
  end
end
