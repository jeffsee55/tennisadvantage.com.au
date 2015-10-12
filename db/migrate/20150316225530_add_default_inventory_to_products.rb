class AddDefaultInventoryToProducts < ActiveRecord::Migration
  def change
    change_column :products, :inventory, :integer, default: 12
  end
end