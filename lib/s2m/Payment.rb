class Payment
  attr_accessor :day, :product, :price, :large_category_id, :middle_category_id, :wallet_name
  def initialize(day, product, price, large_category_id, middle_category_id, wallet_name)
    @day = day 
    @product = product 
    @price = price
    @large_category_id = large_category_id
    @middle_category_id = middle_category_id
    @wallet_name = wallet_name
  end

  def to_s
    "#{@day.month.to_s+ "/" + @day.day.to_s} #{@product} #{@price}"
  end
end
