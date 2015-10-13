class Order < ActiveRecord::Base
  has_many :line_items
  has_many :events, class_name: "OrderEvent"

  register_currency :aud
  monetize :sub_total, :with_model_currency => :aud
  monetize :shipping_rate, :with_model_currency => :aud
  monetize :total, :with_model_currency => :aud

  include Scopes
  default_scope -> { order('created_at DESC') }

  attr_accessor :weight, :length, :width, :height

  SHIPPING_RATE = 10.to_money
  STATES = %w[initialized pending purchased shipped completed]
  COMPANY_ADDRESS = {
        name: "Gregson's Tennis Advantage",
        street1: '11 Parkwood Pl',
        city: 'Sydney',
        state: 'NSW',
        zip: '2151',
        country: 'Australia'
      }
  delegate :initialized?, :pending?, :purchased?, :shipped?, :completed?, to: :current_state

  def receipt
    Receipts::Receipt.new(
      id: id,
      product: "Tennis Advantage",
      company: {
        name: "Gregson's Tennis Advantage",
        address: "11 Parkwood Pl, North Rocks, NSW, 2151",
        email: "sg370@bigpond.com",
        logo: Rails.root.join("app/assets/images/logo.png")
      },
      line_items: [
        ["Date", created_at.strftime("%B %d, %Y")],
        ["Email", "#{email}"],
        ["Delivery Method", delivery_method],
        ["Card", "**** **** **** #{card_last4}"],
        ["Total", "$#{(total).to_s}"]
        #line_items.map(&:product).each do |product|
          #["Product", product.name]
        #end.join(',')
      ],
      font: {
        bold: Rails.root.join('app/assets/fonts/Lato-Bold.ttf'),
        normal: Rails.root.join('app/assets/fonts/Lato-Regular.ttf')
      }
    )
  end

  def current_state
    (events.last.try(:state) || STATES.first).inquiry
  end

  def prepare_order(order, stripe_token, line_items )
    stripe_customer = Stripe::Customer.create(
      email: order[:email],
      source: stripe_token
    )
    self.card_last4 = stripe_customer.sources.first.last4
    self.card_brand = stripe_customer.sources.first.brand
    self.stripe_customer_id = stripe_customer.id
    self.attributes= line_items.dimensions_and_weight
    self.save
    events.create! state: "pending"
  end

  def purchase
    stripe_charge = Stripe::Charge.create(
      amount: self.total_cents,
      currency: "aud",
      customer: self.stripe_customer_id,
      metadata: {
        order_id: self.id,
        sub_total: self.sub_total,
        shipping_rate:self.shipping_rate
      }
    )
    self.charge_id = stripe_charge.id
    self.save
    SiteMailer.new_order(self)
    SiteMailer.order_confirmation(self)

    if self.hand_deliver?
      events.create! state: "completed"
    else
      events.create! state: "purchased"
    end
  end

  def complete
    events.create! state: "completed"
  end

  def incomplete
    events.create! state: "purchased"
  end

  def shipping_rate
    if hand_deliver?
      return 0
    else
      SHIPPING_RATE
    end
  end

  def sub_total
    sum = 0
    line_items.collect do |item|
      sum += item.total
    end
    return sum
  end

  def total
    return self.sub_total + self.shipping_rate
  end

  def total_cents
    ( total.to_f * 100 ).to_i
  end

  def full_address
    {
      name: name || "Other User",
      street1: street1 || "421 Duncan Chapel Rd",
      street2: street2 || "136",
      city: city || "Greenville",
      state: state || "SC",
      zip: zip || "29617",
      counry: country || "US"
    }
  end

  def address_to_string
    full_address.map { |k, v| v }.reject{|i| i.empty?}.join("<br>")
  end

  def dimensions_and_weight
    {
      weight: self.weight,
      height: self.height,
      length: self.length,
      width: self.width
    }
  end

  def send_email
    SiteMailer.new_order(self)
  end

  def delivery_method
    if self.hand_deliver?
      "Hand Deliver"
    else
      "Shipment"
    end
  end

  def delivery_info
    if hand_deliver?
      "We will be in touch shortly with arrangements for hand delivery."
    else
      "You should receive your shipment in 7 to 10 business days. If you have not received it after 10 days, please contact us at sg370@bigpond.com.au"
    end
  end

  def current_state_color
    if current_state == "purchased"
      return "warning-bg"
    end
    if current_state == "shipped"
      return "success-bg"
    end
    if current_state == "completed"
      return "success-bg"
    end
  end

  def current_state_icon
    if current_state == "purchased"
      return "fa-usd"
    end
    if current_state == "shipped"
      return "fa-truck"
    end
    if current_state == "completed"
      return "fa-check"
    end
  end

  def to_local_list_item
    {
      img: nil,
      color: current_state_color,
      icon: current_state_icon,
      primary: "Order ##{ self.id}",
      link: Rails.application.routes.url_helpers.admin_order_path(self),
      link_text: "View Order",
      secondary: "Status: #{self.current_state.capitalize}",
      details: "Delivery method: #{self.delivery_method}"
    }
  end

  def to_public_local_list_item
    {
      img: nil,
      color: current_state_color,
      icon: 'fa-check',
      primary: "Order ##{ self.id}",
      link: "javascript:void(0)",
      link_text: "$#{self.total}",
      secondary: "Status: #{self.current_state.capitalize}",
      details: ("<a href=#{Rails.application.routes.url_helpers.order_path(self, format: 'pdf')} target='_blank'>Print Receipt</a>".html_safe)
    }
  end
end

