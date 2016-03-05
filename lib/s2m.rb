# coding: utf-8

s2m_directory = File.expand_path(File.dirname(__FILE__))

require File.expand_path(File.join(s2m_directory, 's2m/MoneyForward'))
require File.expand_path(File.join(s2m_directory, 's2m/Payment'))
require File.expand_path(File.join(s2m_directory, 's2m/Seikyo'))

require 'dotenv'

module S2m

end

def main
	Dotenv.load

	seikyo = Seikyo.new
	seikyo.login

	payments = seikyo.get_payment_history

	moneyforward = MoneyForward.new
	moneyforward.login

	account = moneyforward.select_account

	last_payment_date = moneyforward.get_last_payment_date(account)
	payments.delete_if {|payment| payment.day <= last_payment_date}

	puts "追加されていない支払いが " + payments.size.to_s + " 件あります．"

	payments.each do |payment|
		moneyforward.add_history(payment)
	end

	if payments.size != 0
		moneyforward.record_last_payment_date(payments[0].day)
	end

	puts "終了します"
end

main()
