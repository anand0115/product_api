class ProductService
  class CreationError < StandardError; end

  attr_reader :product, :errors

  def initialize(params, current_user = nil)
    @params = params.to_h.with_indifferent_access
    @current_user = current_user
    @errors = []
  end

  def create
    validate_params
    return false if @errors.any?

    @product = Product.new(permitted_params)
    
    if @product.save
      notify_creation if should_notify?
      log_creation
      true
    else
      @errors = @product.errors.full_messages
      false
    end
  rescue StandardError => e
    @errors << "An unexpected error occurred: #{e.message}"
    Rails.logger.error("ProductService::CreationError: #{e.message}")
    false
  end

  def self.create(params, current_user = nil)
    service = new(params, current_user)
    service.create
    service
  end

  private

  def validate_params
    @errors << "Name is required" if @params[:name].blank?
    @errors << "Price is required" if @params[:price].blank?
    @errors << "Price must be a positive number" if @params[:price].present? && @params[:price].to_f < 0
    @errors << "Status must be 'active' or 'archived'" if @params[:status].present? && !%w[active archived].include?(@params[:status])
    @errors << "Stock quantity must be a non-negative integer" if @params[:stock_quantity].present? && @params[:stock_quantity].to_i < 0
  end

  def permitted_params
    {
      name: @params[:name],
      price: @params[:price],
      status: @params[:status] || 'active',
      stock_quantity: @params[:stock_quantity] || 0
    }
  end

  def should_notify?
    # Can be extended to check notification preferences
    Rails.env.production?
  end

  def notify_creation
    # Placeholder for notification logic (email, webhook, etc.)
    # ProductMailer.created(@product, @current_user).deliver_later
  end

  def log_creation
    Rails.logger.info("Product created: ID=#{@product.id}, Name=#{@product.name}, By=#{@current_user&.email || 'system'}")
  end
end
