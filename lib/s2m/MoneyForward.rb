# coding: utf-8
require 'mechanize'
require 'openssl'
require 'nokogiri'
require 'io/console'

class MoneyForward
  def initialize(id, pass)
    @agent = Mechanize.new{|a| a.ssl_version, a.verify_mode = "SSLv23", OpenSSL::SSL::VERIFY_NONE}
    @login_url = 'https://moneyforward.com/users/sign_in'
    @base_url = 'https://moneyforward.com/'
    @data_dir = File.expand_path("../../../data", __FILE__)

    count = 0
    begin
      login(id, pass)

      count += 1
      if count == 3
        STDERR.puts "Failed to login to the MoneyForward.\n"
        exit 1
      end
    end while not login?
  end

  private
  def login(id, pass)
    if id == nil
      $logger.error('MONEYFORWARD_ID not found.')
      return false
    end

    if pass == nil
      $logger.error('MONEYFORWARD_PASSWORD not found.')
      return false
    end

    @agent.get(@login_url) do |page|
      page.form_with(:id => 'new_sign_in_session_service') do  |form|
        form.field_with(:name => "sign_in_session_service[email]").value = id 
        form.field_with(:name => "sign_in_session_service[password]").value = pass 
      end.click_button
    end
    sleep 1

    if not login?
      $logger.error("Failed to login to the MoneyForward.")
      return false
    end

    while need_two_step_verifications?
      two_step_verifications

      if need_two_step_verifications?
        $logger.error("Failed to two step verifications.")
        return false
      end
    end

    true
  end

  #ensure: ログアウトする
  public
  def sign_out
    sign_out_url = "https://moneyforward.com/users/sign_out"
    @agent.delete(sign_out_url)
    sleep 1
  end

  #require: ログインが終わっている
  #ensure: 2段階認証を完了する
  private
  def two_step_verifications
    print "2段階認証のコードを入力してください: "
    verification_code = STDIN.gets.chomp

    two_step_verifications_url = "https://moneyforward.com/users/two_step_verifications"
    @agent.get(two_step_verifications_url) do |page|
      page.form_with(:action => '/users/two_step_verifications/verify') do |form|
        form.field_with(:name => "verification_code").value = verification_code
      end.click_button
    end
    sleep 1
  end

  private
  def need_two_step_verifications?
    return @agent.page.uri.to_s.include?("two_step_verifications")
  end

  private
  def login?
    begin
      return !@agent.page.search("//a[@href=\"/users/sign_out\"]").empty?
    rescue
      false
    end
  end

  public
  def add_payment_hisoty(payments)
    last_payment_date = get_last_payment_date(account)
    payments.delete_if {|payment| payment.day <= last_payment_date}

    puts "#{payments.size}件の支払いを追加します"

    payments.each do |payment|
      add_history(payment)
    end

    if payments.size != 0
      record_last_payment_date(payments[0].day)
    else
      record_last_payment_date(last_payment_date)
    end
  end

  #ensure: 支払情報をMoneyFowardに登録する
  private
  def add_history(payment)
    @agent.get("https://moneyforward.com/")
    sleep 1

    puts payment.to_s
    @agent.page.form_with(:id => "js-cf-manual-payment-entry-form") do |form|
      form["user_asset_act[large_category_id]"] = payment.large_category_id
      form["user_asset_act[middle_category_id]"] = payment.middle_category_id
      form.field_with(:name => "user_asset_act[sub_account_id_hash]").option_with(:value => @payment_account[0]).click
      form.field_with(:id => "js-cf-manual-payment-entry-amount").value = payment.price
      form["user_asset_act[updated_at]"] = payment.day.year.to_s + "/" + payment.day.month.to_s + "/" + payment.day.day.to_s
      form["user_asset_act[content]"] = payment.product
    end.click_button
    sleep 1
  end

  #TODO: 振替はしていないので，財布の方のお金の整合性が合わなくなる
  public
  def fix_balance(seikyo_balance)
	  goto_account_page(account[1])
	  rollover(seikyo_balance)
  end

  #残高修正
  public
  def rollover(balance)
    @agent.page.form_with(:id => "rollover_form") do |form|
      form["rollover_info[value]"] = balance
      form["rollover_info[transaction_flag]"] = 0
	  form["rollover_info[updated_at]"] = "#{Time.now.year}/#{Time.now.month}/#{Time.now.day}"
	end.click_button
	sleep 1
  end

  private
  def goto_account_page(account_name)
   href = @agent.page.search("//a[.=\"#{account_name.strip}\"]").attribute("href")
   url = "https://moneyforward.com#{href}"
   @agent.get(url)
   sleep 1
  end

  #require: 使用する口座
  #ensure: 口座の最終出金日を与える
  private
  def get_last_payment_date(account)
    account_name = account[1]
    last_payment_date_file = File.expand_path("last_payment_date", @data_dir)

    if not File.exist?(last_payment_date_file)
      puts "最後に#{account_name}で出金した日付を記入してください"
      print "年: "
      year = STDIN.gets.chomp
      print "月: "
      month = STDIN.gets.chomp
      print "日: "
      day = STDIN.gets.chomp

      return Time.gm(year, month, day, 0, 0, 0)
    else 
      File.open(last_payment_date_file) do |file|
        file_str = file.read.split(" ")
        return Time.gm(file_str[0], file_str[1], file_str[2], 0, 0, 0)
      end
    end
  end

  private
  def record_last_payment_date(last_payment_date)
    last_payment_date_file = File.expand_path("last_payment_date", @data_dir)

    if not File.exist?(last_payment_date_file)
      if not Dir.exist?(@data_dir)
        Dir.mkdir(@data_dir, 0777)
      end
      File.open(last_payment_date_file, "w")
    end

    str = "#{last_payment_date.year} #{last_payment_date.month} #{last_payment_date.day}"
    File.write(last_payment_date_file, str)
  end

  # 登録されている財布から支払元を選択
  private
  def account
    accounts = []
    key = []

    @agent.get("https://moneyforward.com/")
    sleep 1

    @agent.page.form_with(:id => "js-cf-manual-payment-entry-form") do |form|
      form.field_with(:name => "user_asset_act[sub_account_id_hash]") do |select|
        select.options.each do |option|
          accounts << option.text.to_s
          key << option.value.to_s
        end
      end
    end

    account_num  = accounts.index(get_account_name)

    while account_num == nil
      for i in 1..accounts.size-1
        puts i.to_s + " " + accounts[i-1].to_s
      end

      print "どの支出元を使用しますか？: "
      account_num = STDIN.gets.chomp.to_i-1

      if 0 <= account_num and account_num < accounts.size
        record_account(accounts[account_num].to_s)
        break
      else
        puts "正しい数値を入力してください"
        account_num = nil
      end
    end
    @payment_account = [key[account_num].to_s, accounts[account_num].to_s]
    @payment_account
  end

  private
  def get_account_name
    account_file = File.expand_path("account", @data_dir)
    account_name = nil

    if File.exist?(account_file)
      File.open(account_file) do |file|
        account_name = file.read
      end
    end

    account_name
  end

  private
  def record_account(account)
    account_file = File.expand_path("account", @data_dir)

    if not File.exist?(account_file)
      if not Dir.exist?(@data_dir)
        Dir.mkdir(@data_dir, 0777)
      end
      File.open(account_file, "w")
    end

    File.write(account_file, account)
  end
end
