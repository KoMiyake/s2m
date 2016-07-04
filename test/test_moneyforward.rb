require 'test/unit'
require 'dotenv'

require File.expand_path('lib/s2m/MoneyForward')

class MoneyForwardTest < Test::Unit::TestCase
	def setup
		Dotenv.load File.expand_path(File.join(File.expand_path(File.dirname(__FILE__)), '../.env'))
		@moneyforward = MoneyForward.new
	end

	def test_login
		assert @moneyforward.login(ENV['MONEYFORWARD_ID'], ENV['MONEYFORWARD_PASS']), "正しいIDとPassの入力でログインが成功する"
		@moneyforward.sign_out

		sleep 3
		assert (not @moneyforward.login("hoge", "hogehoge")), "間違ったIDとPassを入れるとログインが失敗する"
	end

	def test_login?
		assert (not @moneyforward.login?), "ログインしていない場合，login?はfalseを返す"
		@moneyforward.login(ENV['MONEYFORWARD_ID'], ENV['MONEYFORWARD_PASS'])
		assert @moneyforward.login?, "ログインしている場合，login?はtrueを返す"
	end
	
	def test_sign_out
		@moneyforward.login(ENV['MONEYFORWARD_ID'], ENV['MONEYFORWARD_PASS'])
		@moneyforward.sign_out
		assert (not @moneyforward.login?), "ログアウトしたならば，ログイン状態ではない"
	end
end
