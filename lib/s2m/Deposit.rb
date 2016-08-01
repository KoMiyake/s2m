class Deposit
	attr_accessor :day, :price, :large_category_id, :middle_category_id
	def initialize(day, price, large_category_id, middle_category_id)
		@day, @price, @large_category_id, @middle_category_id = day, price, large_category_id, middle_category_id
	end

	def to_s
		"#{@day.month_to_s + "/" + @day.day.to_s} #{@price}"
	end
end
