FactoryBot.define do
  factory :product do
    name { Faker::Commerce.product_name }
    price { Faker::Commerce.price(range: 10.0..100.0) }
    status { 'active' }
    stock_quantity { Faker::Number.between(from: 1, to: 100) }

    trait :archived do
      status { 'archived' }
    end

    trait :out_of_stock do
      stock_quantity { 0 }
    end
  end
end
