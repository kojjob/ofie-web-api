module Cacheable
  extend ActiveSupport::Concern

  included do
    after_commit :clear_cache
  end

  class_methods do
    # Cache key for collections
    def cache_key_for_collection(records)
      {
        model: model_name.cache_key,
        count: records.count,
        max_updated_at: records.maximum(:updated_at)&.to_i
      }.to_json
    end

    # Cached find method
    def cached_find(id)
      Rails.cache.fetch(["model", model_name.cache_key, id], expires_in: 1.hour) do
        find(id)
      end
    end

    # Cached collection methods
    def cached_all
      Rails.cache.fetch([model_name.cache_key, "all"], expires_in: 1.hour) do
        all.to_a
      end
    end

    def cached_recent(limit = 10)
      Rails.cache.fetch([model_name.cache_key, "recent", limit], expires_in: 30.minutes) do
        order(created_at: :desc).limit(limit).to_a
      end
    end

    # Clear all caches for this model
    def clear_model_cache
      Rails.cache.delete_matched("#{model_name.cache_key}/*")
    end
  end

  # Instance methods
  def cache_key_with_version
    "#{model_name.cache_key}/#{id}-#{updated_at.to_i}"
  end

  def cached_associations(*associations)
    Rails.cache.fetch([cache_key_with_version, "associations", associations], expires_in: 1.hour) do
      result = self
      associations.each do |association|
        result = result.public_send(association)
      end
      result
    end
  end

  private

  def clear_cache
    # Clear instance cache
    Rails.cache.delete(["model", model_name.cache_key, id])
    
    # Clear collection caches
    Rails.cache.delete([model_name.cache_key, "all"])
    Rails.cache.delete_matched("#{model_name.cache_key}/recent/*")
    
    # Clear associated caches
    clear_associated_caches
  end

  def clear_associated_caches
    # Override in including models to clear specific associated caches
  end
end