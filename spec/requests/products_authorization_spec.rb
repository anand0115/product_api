require 'rails_helper'

RSpec.describe 'Product Authorization', type: :request do
  let!(:admin) { create(:user, :admin) }
  let!(:user) { create(:user) }
  let!(:product) { create(:product) }

  describe 'GET /api/v1/products (index)' do
    context 'as admin' do
      it 'allows access' do
        get '/api/v1/products', headers: auth_headers_for(admin)
        expect(response).to have_http_status(:ok)
      end
    end

    context 'as regular user' do
      it 'allows access' do
        get '/api/v1/products', headers: auth_headers_for(user)
        expect(response).to have_http_status(:ok)
      end
    end

    context 'without authentication' do
      it 'denies access' do
        get '/api/v1/products'
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/v1/products/:id (show)' do
    context 'as admin' do
      it 'allows access' do
        get "/api/v1/products/#{product.id}", headers: auth_headers_for(admin)
        expect(response).to have_http_status(:ok)
      end
    end

    context 'as regular user' do
      it 'allows access' do
        get "/api/v1/products/#{product.id}", headers: auth_headers_for(user)
        expect(response).to have_http_status(:ok)
      end
    end

    context 'without authentication' do
      it 'denies access' do
        get "/api/v1/products/#{product.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/v1/products (create)' do
    let(:valid_params) do
      {
        product: {
          name: 'New Product',
          price: 29.99,
          status: 'active',
          stock_quantity: 50
        }
      }
    end

    context 'as admin' do
      it 'allows creating products' do
        expect {
          post '/api/v1/products', params: valid_params, headers: auth_headers_for(admin), as: :json
        }.to change(Product, :count).by(1)
      end

      it 'returns created status' do
        post '/api/v1/products', params: valid_params, headers: auth_headers_for(admin), as: :json
        expect(response).to have_http_status(:created)
      end
    end

    context 'as regular user' do
      it 'denies access with 403 Forbidden' do
        post '/api/v1/products', params: valid_params, headers: auth_headers_for(user), as: :json
        expect(response).to have_http_status(:forbidden)
      end

      it 'does not create product' do
        expect {
          post '/api/v1/products', params: valid_params, headers: auth_headers_for(user), as: :json
        }.not_to change(Product, :count)
      end

      it 'returns error message' do
        post '/api/v1/products', params: valid_params, headers: auth_headers_for(user), as: :json
        expect(json_response['error']).to eq('Forbidden')
        expect(json_response['message']).to eq('Admin access required')
      end
    end

    context 'without authentication' do
      it 'denies access' do
        post '/api/v1/products', params: valid_params, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PUT /api/v1/products/:id (update)' do
    let(:update_params) { { product: { name: 'Updated Name' } } }

    context 'as admin' do
      it 'allows updating products' do
        put "/api/v1/products/#{product.id}", params: update_params, headers: auth_headers_for(admin), as: :json
        expect(response).to have_http_status(:ok)
        expect(product.reload.name).to eq('Updated Name')
      end
    end

    context 'as regular user' do
      it 'denies access with 403 Forbidden' do
        put "/api/v1/products/#{product.id}", params: update_params, headers: auth_headers_for(user), as: :json
        expect(response).to have_http_status(:forbidden)
      end

      it 'does not update product' do
        original_name = product.name
        put "/api/v1/products/#{product.id}", params: update_params, headers: auth_headers_for(user), as: :json
        expect(product.reload.name).to eq(original_name)
      end
    end

    context 'without authentication' do
      it 'denies access' do
        put "/api/v1/products/#{product.id}", params: update_params, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /api/v1/products/:id (destroy)' do
    context 'as admin' do
      it 'allows deleting products' do
        expect {
          delete "/api/v1/products/#{product.id}", headers: auth_headers_for(admin)
        }.to change(Product, :count).by(-1)
      end

      it 'returns no content status' do
        delete "/api/v1/products/#{product.id}", headers: auth_headers_for(admin)
        expect(response).to have_http_status(:no_content)
      end
    end

    context 'as regular user' do
      it 'denies access with 403 Forbidden' do
        delete "/api/v1/products/#{product.id}", headers: auth_headers_for(user)
        expect(response).to have_http_status(:forbidden)
      end

      it 'does not delete product' do
        expect {
          delete "/api/v1/products/#{product.id}", headers: auth_headers_for(user)
        }.not_to change(Product, :count)
      end
    end

    context 'without authentication' do
      it 'denies access' do
        delete "/api/v1/products/#{product.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'Error handling' do
    context 'when product not found' do
      it 'returns 404 for admin' do
        get '/api/v1/products/99999', headers: auth_headers_for(admin)
        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('Record not found')
      end

      it 'returns 404 for user' do
        get '/api/v1/products/99999', headers: auth_headers_for(user)
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with validation errors' do
      it 'returns 422 with error messages' do
        post '/api/v1/products', 
             params: { product: { name: '', price: -1 } }, 
             headers: auth_headers_for(admin), 
             as: :json
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to be_present
      end
    end
  end
end
