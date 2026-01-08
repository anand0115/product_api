class Product < ApplicationRecord
  enum :status, { active: 0, archived: 1 }

  validates :name, presence: true, length: { minimum: 2, maximum: 255 }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true
  validates :stock_quantity, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :list_fields, -> { select(:id, :name, :price, :status, :stock_quantity, :created_at, :updated_at) }
  scope :active_only, -> { where(status: :active) }
  scope :in_stock, -> { where('stock_quantity > 0') }

  after_commit :invalidate_cache

  private

  def invalidate_cache
    Rails.cache.delete_matched("products/*")
    Rails.cache.delete("products/#{id}-*")
  end
end
