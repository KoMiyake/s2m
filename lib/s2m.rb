# coding: utf-8

s2m_directory = File.expand_path(File.dirname(__FILE__))
log_file = File.expand_path(File.join(s2m_directory, '../log/s2m.log'))

require File.expand_path(File.join(s2m_directory, 's2m/MoneyForward'))
require File.expand_path(File.join(s2m_directory, 's2m/Payment'))
require File.expand_path(File.join(s2m_directory, 's2m/Deposit'))
require File.expand_path(File.join(s2m_directory, 's2m/Seikyo'))

require 'dotenv'
require 'logger'

if not File.exist?(log_file)
  log_dir = File.expand_path(File.join(s2m_directory, '../log'))
  if not Dir.exist?(log_dir)
    Dir.mkdir(log_dir, 0777)
  end
  File.open(log_file, "w")
end
$logger = Logger.new(log_file)
Dotenv.load File.expand_path(File.join(File.expand_path(File.dirname(__FILE__)), '../.env'))


def main
  seikyo = Seikyo.new(ENV['SEIKYO_ID'], ENV['SEIKYO_PASS'])
  payments = seikyo.get_payment_history

  moneyforward = MoneyForward.new(ENV['MONEYFORWARD_ID'], ENV['MONEYFORWARD_PASS'])
  moneyforward.add_payment_hisoty(payments)
end

main()
