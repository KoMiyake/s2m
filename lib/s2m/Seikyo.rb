# coding: utf-8
require 'mechanize'
require 'openssl'
require 'nokogiri'
require 'io/console'

class Seikyo
  LARGE_CATEGORY_ID_OF_FOOD_EXPENSES = 11
  MIDDLE_CATEGORY_ID_OF_EATING_OUT = 42
  
  DEPOSIT_HISTORY = "PaymentHistoryFormCsvDownload"
  PAYMENT_HISTORY = "AllHistoryFormCsvDownload"

  def initialize(id, pass)
    @agent = Mechanize.new{|a| a.ssl_version, a.verify_mode = 'SSLv23', OpenSSL::SSL::VERIFY_NONE}
    @login_url = 'https://mp.seikyou.jp/mypage/Static.init.do'

    count = 0
    begin
      login(ENV['SEIKYO_ID'], ENV['SEIKYO_PASS'])

      count += 1
      if count == 3
        STDERR.puts "Failed to login to the Seikyo.\n"
        exit 1
      end
    end while not login? 
  end

  private
  def login(id, pass)
    if id == nil
      $logger.error('SEIKYO_ID not found.')
      return false
    end

    if pass == nil
      $logger.error('SEIKYO_PASS not found.')
      return false
    end

    @agent.get(@login_url) do |page|
      page.form_with(:name => 'loginForm') do  |form|
        form.field_with(:name => "loginId").value = id 
        form.field_with(:name => "password").value = pass 
      end.click_button
    end
    sleep 1

    if not login?
      $logger.error('Failed to login to the Seikyo.')
      return false
    end
    return true
  end

  private
  def login?
    begin
      return !@agent.page.search("//img[@alt=\"ログイン中\"]").empty?
    rescue
      false
    end
  end

  private
  def analysis_payment_cvs(cvs_file)
    payments = []
    # 文字コードの問題でcvsファイルが読み込めないので，nkfコマンドでUTF-8に直している
    system("nkf -w --overwrite " + cvs_file)

    File.open(cvs_file) do |file|
      file_str = file.read
      file_str.split("\n").slice!(2..file_str.split("\n").size()-1).each do |data|
        data.gsub!("\"", "")

        data = data.split(",")
        date = data[0].split("(")[0].split("/")
        day = Time.gm(Time.now.year, date[0].to_i, date[1].to_i, 0, 0, 0)
        if Time.now < day
          day = Time.gm(Time.now.year-1, date[0].to_i, date[1].to_i, 0, 0, 0)
        end

        product = data[2]
        price = data[4]

        payments << Payment.new(day, product, price, LARGE_CATEGORY_ID_OF_FOOD_EXPENSES, MIDDLE_CATEGORY_ID_OF_EATING_OUT)
      end
    end

    payments
  end

  #TODO: analysis_payment_cvsとまとめてもよさそう
  private
  def analysis_deposit_cvs(cvs_file)
    deposits = []
    # 文字コードの問題でcvsファイルが読み込めないので，nkfコマンドでUTF-8に直している
    system("nkf -w --overwrite " + cvs_file)

    File.open(cvs_file) do |file|
      file_str = file.read
      file_str.split("\n").slice!(2..file_str.split("\n").size()-1).each do |data|
        data.gsub!("\"", "")

        data = data.split(",")
        date = data[0].split("(")[0].split("/")
        day = Time.gm(Time.now.year, date[0].to_i, date[1].to_i, 0, 0, 0)
        if Time.now < day
          day = Time.gm(Time.now.year-1, date[0].to_i, date[1].to_i, 0, 0, 0)
        end

        price = data[3]

        deposits << Deposit.new(day, price, 1, 1)
      end
    end

    deposits
  end

  # 2ヶ月分の入金履歴をとってくる
  public
  def get_deposit_history
    change_page("PAYMENT_HISTORY")
    get_all_history(DEPOSIT_HISTORY)
  end
  
  # 2ヶ月分の購買履歴をとってくる
  public
  def get_payment_history
    change_page("ALL_HISTORY")
    payments = get_all_history(PAYMENT_HISTORY) 

    goto_last_month_history_page
    payments = payments + get_all_history(PAYMENT_HISTORY)

    payments
  end

  #残高をとってくる
  public
  def get_balance
    @agent.get("https://mp.seikyou.jp/mypage/Menu.change.do")
    sleep 1
	@agent.page.search("//*[@id=\"point_zandaka\"]/table/tr[2]/td/span").text.gsub(",", "")
  end

  private
  def goto_last_month_history_page
    change_page("ALL_HISTORY")

    form = @agent.page.form_with(:name => "AllHistoryFormChangeDate")
    form.field_with(:name => "rirekiDate").options.first.select
    @agent.submit(form)
    sleep 1
  end
  
  #購入履歴，入金履歴等のページに切り替える
  private
  def change_page(menu)
    @agent.get("https://mp.seikyou.jp/mypage/Menu.change.do")
    sleep 1
    
    form =  @agent.page.form("menuForm")
    form.id = menu 
    form.action = "/mypage/Menu.change.do" + "?pageNm=" + menu 
    @agent.submit(form)
    sleep 1
  end

  #TODO: テストしやすい形にしておく
  private
  def get_all_history(history)
    cvs_file = create_file_name()

    form = @agent.page.form(history)
    @agent.submit(form).save_as(cvs_file)
    
    result = analysis_payment_cvs(cvs_file) if history == PAYMENT_HISTORY
    result = analysis_deposit_cvs(cvs_file) if history == DEPOSIT_HISTORY
    
    File.delete cvs_file

    return result
  end

  private
  def create_file_name
    begin
      file_name = "/tmp/" + (0...8).map{ (65 + rand(26)).chr }.join
    end while File.exist? file_name
    file_name
  end
end
