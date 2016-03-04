# coding: utf-8

s2m_directory = File.expand_path(File.dirname(__FILE__))

require File.expand_path(File.join(s2m_directory, 's2m/MoneyForward'))
require File.expand_path(File.join(s2m_directory, 's2m/Payment'))
require File.expand_path(File.join(s2m_directory, 's2m/Seikyo'))

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
