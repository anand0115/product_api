module Authorization
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  # 403 - Forbidden (admin only resources)
  def authorize_admin!
    return if current_user&.admin?

    render json: {
      error: 'Forbidden',
      message: 'Admin access required'
    }, status: :forbidden
  end

  # Generic role check for future extensibility
  def authorize_role!(*roles)
    return if roles.any? { |role| current_user&.send("#{role}?") }

    render json: {
      error: 'Forbidden',
      message: "Required role: #{roles.join(' or ')}"
    }, status: :forbidden
  end
end
