# coding: utf-8

s2m_directory = File.expand_path(File.dirname(__FILE__))

require File.expand_path(File.join(s2m_directory, 's2m/MoneyForward'))
require File.expand_path(File.join(s2m_directory, 's2m/Payment'))
require File.expand_path(File.join(s2m_directory, 's2m/Seikyo'))

require 'dotenv'

def main
	Dotenv.load File.expand_path(File.join(File.expand_path(File.dirname(__FILE__)), '../.env'))

	seikyo = Seikyo.new

	#TODO: カウントしてlogin失敗しまくったらexitする
	begin
		seikyo.login(ENV['SEIKYO_ID'], ENV['SEIKYO_PASS'])
	end while not seikyo.login?

	payments = seikyo.get_payment_history

	moneyforward = MoneyForward.new

	#TODO: カウントしてlogin失敗しまくったらexitする
	begin
		moneyforward.login(ENV['MONEYFORWARD_ID'], ENV['MONEYFORWARD_PASS'])
	end while not moneyforward.login?

	moneyforward.add(payments)

	puts "終了します"
end

main()
