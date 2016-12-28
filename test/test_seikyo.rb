require 'test/unit'
require 'dotenv'

require File.expand_path('lib/s2m/Seikyo')
require File.expand_path('lib/s2m/Deposit')
require File.expand_path('lib/s2m/Payment')

class SeikyoTest < Test::Unit::TestCase
  def setup
    Dotenv.load File.expand_path(File.join(File.expand_path(File.dirname(__FILE__)), '../.env'))
    @seikyo = Seikyo.new
    
    s2m_directory = File.expand_path(File.dirname(__FILE__))
    $logger = Logger.new(File.expand_path(File.join(s2m_directory, '../log/s2m.log')))
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

  def test_change_page
    @seikyo.login(ENV['SEIKYO_ID'], ENV['SEIKYO_PASS'])
    @seikyo.send(:change_page, "ALL_HISTORY")
    assert @seikyo.instance_variable_get('@agent').page.uri.to_s.include?("ALL_HISTORY"), "出勤履歴を取得するページに到達している"
    @seikyo.send(:change_page, "PAYMENT_HISTORY")
    assert @seikyo.instance_variable_get('@agent').page.uri.to_s.include?("PAYMENT_HISTORY"), "入金履歴を取得するページに到達している"
  end

  def test_analysis_cvs

  end

  def test_create_file_name

  end
end
