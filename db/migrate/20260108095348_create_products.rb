class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name
      t.decimal :price
      t.integer :status
      t.integer :stock_quantity

      t.timestamps
    end
  end
end
