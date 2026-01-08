class AddIndexesToProducts < ActiveRecord::Migration[8.1]
  def change
    # Index for sorting/searching by name
    add_index :products, :name, name: 'index_products_on_name'
  end
end
