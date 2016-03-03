# coding: utf-8
lib = File.expand_path('../', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
Dir[File.expand_path('./s2m') << '/*.rb'].each do |file|
	require file
end

module S2m

end

def main
	seikyo = Seikyo.new
	seikyo.login

	payments = seikyo.get_payment_history

	moneyforward = MoneyForward.new
	moneyforward.login

	last_payment_date = moneyforward.get_last_payment_date
	payments.delete_if {|payment| payment.day <= last_payment_date}

	puts "追加されていない支払いが " + payments.size.to_s + " 件あります．"

	payments.each do |payment|
		moneyforward.add_history(payment)
	end

	puts "終了します"
end

main()
