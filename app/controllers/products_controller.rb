class ProductsController < ApplicationController
  before_action :set_product, only: :show
  def show
    @products = Product.all
  end

  def index
    products = Product.all
    @tournament_player_products = products.where(category: "Tournament Racquets")
    @competition_player_products = products.where(category: "Competition, Intermediate & Junior Racquets")
    @page = Page.find_by_slug("products")
  end

  private

    def set_product
      @product = Product.find(params[:id])
    end
end

