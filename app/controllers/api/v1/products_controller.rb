module Api
  module V1
    class ProductsController < ApplicationController
      include Authorization
      include Paginatable
      include Cacheable

      before_action :authorize_admin!, only: [:create, :update, :destroy]
      before_action :set_product, only: [:show, :update, :destroy]

      def index
        cache_key = collection_cache_key(Product, page_number)

        products = cache_fetch(cache_key) do
          paginate(Product.list_fields.order(:id)).to_a.map(&:as_json)
        end

        paginated_products = paginate(Product.all)

        render json: {
          products: products,
          meta: pagination_meta(paginated_products)
        }
      end

      def show
        product_json = cache_fetch(record_cache_key(@product)) do
          @product.as_json
        end

        render json: { product: product_json }
      end

      def create
        service = ProductService.create(product_params, current_user)

        if service.product&.persisted?
          render json: { product: service.product }, status: :created
        else
          render json: { errors: service.errors }, status: :unprocessable_entity
        end
      end

      def update
        if @product.update(product_params)
          render json: { product: @product }
        else
          render json: { errors: @product.errors }, status: :unprocessable_entity
        end
      end

      def destroy
        @product.destroy
        head :no_content
      end

      private

      def set_product
        @product = Product.find(params[:id])
      end

      def product_params
        params.require(:product).permit(:name, :price, :status, :stock_quantity)
      end
    end
  end
end