# coding: utf-8

s2m_directory = File.expand_path(File.dirname(__FILE__))

require File.expand_path(File.join(s2m_directory, 's2m/MoneyForward'))
require File.expand_path(File.join(s2m_directory, 's2m/Payment'))
require File.expand_path(File.join(s2m_directory, 's2m/Seikyo'))

require 'dotenv'

module S2m

end

def main
	Dotenv.load File.expand_path(File.join(File.expand_path(File.dirname(__FILE__)), '../.env'))

	seikyo = Seikyo.new
	seikyo.login

	payments = seikyo.get_payment_history

	moneyforward = MoneyForward.new
	moneyforward.login

	moneyforward.add(payments)

	puts "終了します"
end

main()
