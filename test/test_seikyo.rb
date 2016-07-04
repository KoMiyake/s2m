require 'test/unit'
require 'dotenv'

require File.expand_path('lib/s2m/Seikyo')

class SeikyoTest < Test::Unit::TestCase
	def setup
		Dotenv.load File.expand_path(File.join(File.expand_path(File.dirname(__FILE__)), '../.env'))
		@seikyo = Seikyo.new
	end

	def test_login
		assert @seikyo.login(ENV['SEIKYO_ID'], ENV['SEIKYO_PASS']), "正しいIDとPassの入力でログインが成功する"

		sleep 3
		assert (not @seikyo.login("hoge", "hogehoge")), "間違ったIDとPassを入れるとログインが失敗する"
	end

	def test_login?
		assert (not @seikyo.login?), "ログインしていない場合，login?はfalseを返す"
		@seikyo.login(ENV['SEIKYO_ID'], ENV['SEIKYO_PASS'])
		assert @seikyo.login?, "ログインした場合，login?はtrueを返す"
	end

	def test_analysis_cvs

	end

	def test_get_payment_history

	end

	def test_create_file_name

	end
end

