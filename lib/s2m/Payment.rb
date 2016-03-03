class Payment
	attr_accessor :day, :place, :product, :point, :price
	def initialize(data)
		data = data.split(",")
		date = data[0].split("(")[0].split("/")
		@day = Time.gm(Time.now.year, date[0].to_i, date[1].to_i, 0, 0, 0)
		if Time.now < day
			day.year = day.year-1
		end

		@place = data[1]
		@product = data[2]
		@point = data[3]
		@price = data[4]
	end

	def output
		print "#{@day.month.to_s+ "/" + @day.day.to_s} @#{@place} : #{@product} #{@price}\n"
	end
end
