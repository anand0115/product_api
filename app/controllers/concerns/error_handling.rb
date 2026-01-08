module ErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
    rescue_from ActionController::ParameterMissing, with: :bad_request
    rescue_from ActionController::BadRequest, with: :bad_request
  end

  private

  def not_found(exception)
    render_error('Record not found', exception.message, :not_found)
  end

  def unprocessable_entity(exception)
    render json: {
      error: 'Validation failed',
      messages: exception.record.errors.full_messages
    }, status: :unprocessable_entity
  end

  def bad_request(exception)
    render_error('Bad request', exception.message, :bad_request)
  end

  def render_error(error, message, status)
    render json: { error: error, message: message }, status: status
  end
end
