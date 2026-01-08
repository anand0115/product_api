require 'rails_helper'

RSpec.describe 'Authentication', type: :request do
  describe 'POST /signup' do
    let(:valid_params) do
      {
        user: {
          email: 'newuser@example.com',
          password: 'password123',
          password_confirmation: 'password123'
        }
      }
    end

    context 'with valid parameters' do
      it 'creates a new user' do
        expect {
          post '/signup', params: valid_params, as: :json
        }.to change(User, :count).by(1)
      end

      it 'returns success status' do
        post '/signup', params: valid_params, as: :json
        expect(response).to have_http_status(:ok)
      end

      it 'returns user data' do
        post '/signup', params: valid_params, as: :json
        expect(json_response['data']['email']).to eq('newuser@example.com')
      end
    end

    context 'with invalid parameters' do
      it 'returns error for missing email' do
        post '/signup', params: { user: { password: 'password123', password_confirmation: 'password123' } }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error for password mismatch' do
        post '/signup', params: { user: { email: 'test@example.com', password: 'password123', password_confirmation: 'different' } }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error for duplicate email' do
        create(:user, email: 'existing@example.com')
        post '/signup', params: { user: { email: 'existing@example.com', password: 'password123', password_confirmation: 'password123' } }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'POST /login' do
    let!(:user) { create(:user, email: 'test@example.com', password: 'password123') }

    context 'with valid credentials' do
      it 'returns success status' do
        post '/login', params: { user: { email: 'test@example.com', password: 'password123' } }, as: :json
        expect(response).to have_http_status(:ok)
      end

      it 'returns JWT token in Authorization header' do
        post '/login', params: { user: { email: 'test@example.com', password: 'password123' } }, as: :json
        expect(response.headers['Authorization']).to be_present
        expect(response.headers['Authorization']).to start_with('Bearer ')
      end

      it 'returns user data' do
        post '/login', params: { user: { email: 'test@example.com', password: 'password123' } }, as: :json
        expect(json_response['data']['email']).to eq('test@example.com')
      end
    end

    context 'with invalid credentials' do
      it 'returns unauthorized for wrong password' do
        post '/login', params: { user: { email: 'test@example.com', password: 'wrongpassword' } }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns unauthorized for non-existent user' do
        post '/login', params: { user: { email: 'nonexistent@example.com', password: 'password123' } }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /logout' do
    let!(:user) { create(:user) }

    context 'with valid token' do
      it 'returns success status' do
        delete '/logout', headers: auth_headers_for(user)
        expect(response).to have_http_status(:ok)
      end

      it 'returns logout message' do
        delete '/logout', headers: auth_headers_for(user)
        expect(json_response['message']).to eq('Logged out successfully.')
      end

      it 'invalidates the token' do
        headers = auth_headers_for(user)
        delete '/logout', headers: headers

        expect(JwtDenylist.count).to eq(1)
      end
    end

    context 'without token' do
      it 'returns unauthorized' do
        delete '/logout'
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'Token expiration and validation' do
    let!(:user) { create(:user) }

    it 'allows access with valid token' do
      get '/api/v1/products', headers: auth_headers_for(user)
      expect(response).to have_http_status(:ok)
    end

    it 'denies access without token' do
      get '/api/v1/products'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'denies access with invalid token' do
      get '/api/v1/products', headers: { 'Authorization' => 'Bearer invalid_token' }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
