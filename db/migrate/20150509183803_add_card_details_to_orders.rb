class AddCardDetailsToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :card_brand, :string
    add_column :orders, :card_last4, :string
  end
end
