class Deposit
  attr_accessor :day, :price, :large_category_id, :middle_category_id, :wallet_name
  def initialize(day, price, large_category_id, middle_category_id, wallet_name)
    @day, @price, @large_category_id, @middle_category_id, @wakket_name = day, price, large_category_id, middle_category_id, wallet_name
  end

  def to_s
    "#{@day.month.to_s + "/" + @day.day.to_s} #{@price}"
  end
end
