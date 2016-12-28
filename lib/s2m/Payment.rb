class Payment
  attr_accessor :day, :product, :price, :large_category_id, :middle_category_id
  def initialize(day, product, price, large_category_id, middle_category_id)
    @day = day 
    @product = product 
    @price = price
    @large_category_id = large_category_id
    @middle_category_id = middle_category_id
  end

  def to_s
    "#{@day.month.to_s+ "/" + @day.day.to_s} #{@product} #{@price}"
  end
end
