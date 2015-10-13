class Admin::OrdersController < AdminController
  before_action :set_order, only: [:show, :edit, :update, :ship, :destroy]

  def show
  end

  def edit
  end

  def index
    @orders = Order.all.page params[:page]
  end

  def update
    if params[:status] == "complete"
      @order.complete
      redirect_to admin_order_path(@order), notice: "Item has been marked completed"
    else
      @order.incomplete
      redirect_to admin_order_path(@order), notice: "Item has been marked purchased but not yet complete"
    end
  end

  def destroy
    @order.delete
    redirect_to admin_orders_path, notice: "Order has been deleted."
  end

  private

    def set_order
      @order = Order.find(params[:id])
    end

    def order_params
      params.require(:order).permit(:name, :street1, :street2, :city, :state, :zip)
    end
end

