class Users::RegistrationsController < Devise::RegistrationsController
  respond_to :json

  def create
    build_resource(sign_up_params)

    resource.save
    if resource.persisted?
      render json: {
        status: { code: 200, message: 'Signed up successfully.' },
        data: { id: resource.id, email: resource.email, role: resource.role }
      }, status: :ok
    else
      clean_up_passwords resource
      render json: {
        status: { message: "User couldn't be created successfully.", errors: resource.errors.full_messages }
      }, status: :unprocessable_entity
    end
  end

  private

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
