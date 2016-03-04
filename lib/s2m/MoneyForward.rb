# coding: utf-8
require 'mechanize'
require 'openssl'
require 'nokogiri'
require 'io/console'

class MoneyForward
	def initialize
		@agent = Mechanize.new{|a| a.ssl_version, a.verify_mode = "SSLv23", OpenSSL::SSL::VERIFY_NONE}
		@login_url = 'https://moneyforward.com/users/sign_in'
		@base_url = 'https://moneyforward.com/'
	end

	def login
		begin
			puts "Login MoneyForward..."
			print "ID: "
			id = STDIN.gets.chomp
			print "Pass: "
			pass = STDIN.noecho(&:gets).chomp
			puts ""

			@agent.get(@login_url) do |page|
				page.form_with(:id => 'new_sign_in_session_service') do  |form|
					form.field_with(:name => "sign_in_session_service[email]").value = id
					form.field_with(:name => "sign_in_session_service[password]").value = pass
				end.click_button
			end
			sleep 1

			if not login?
				puts "ログインに失敗しました"
			end
		end while not login?

		if need_two_step_verifications?
			two_step_verifications
		end
	end

	#require: ログインが終わっている
	#ensure: 2段階認証を完了する
	def two_step_verifications
		begin
			print "2段階認証のコードを入力してください: "
			verification_code = STDIN.gets.chomp

			two_step_verifications_url = "https://moneyforward.com/users/two_step_verifications"
			@agent.get(two_step_verifications_url) do |page|
				page.form_with(:action => '/users/two_step_verifications/verify') do |form|
					form.field_with(:name => "verification_code").value = verification_code
				end.click_button
			end
		end while not need_two_step_verifications?
	end

	def need_two_step_verifications?
		return @agent.page.uri.to_s.include?("two_step_verifications")
	end

	def login?
		return !@agent.page.search("//a[@href=\"/users/sign_out\"]").empty?
	end

	def add_history(payment)
		@agent.get("https://moneyforward.com/")
		sleep 1

		payment.output
		@agent.page.form_with(:id => "js-cf-manual-payment-entry-form") do |form|
			form["user_asset_act[large_category_id]"] = "11"
			form["user_asset_act[middle_category_id]"] = "42"
			form.field_with(:name => "user_asset_act[sub_account_id_hash]").option_with(:value => @payment_account[0]).click
			form.field_with(:id => "js-cf-manual-payment-entry-amount").value = payment.price
			form["user_asset_act[updated_at]"] = payment.day.year.to_s + "/" + payment.day.month.to_s + "/" + payment.day.day.to_s
			form["user_asset_act[content]"] = payment.product
		end.click_button
		sleep 1
	end

	# アカウントの最終更新日時を調べる
	def get_last_payment_date
		account_name = select_account()[1]

		@agent.get("https://moneyforward.com/")
		sleep 1
		@agent.page.links.find{|e| account_name.include?(e.text)}.click
		sleep 1.5
		date = @agent.page.search("//td[@class=\"date form-switch-td\"]/div[@class=\"noform\"]/span").first.text.to_s
		date = date.split("(")[0].split("/")

		day = Time.gm(Time.now.year, date[0].to_i, date[1].to_i, 0, 0, 0)
		if Time.now < day
			day.year = day.year-1
		end

		day
	end

	# 登録されている財布から支払元を選択
	def select_account
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

		while true
			for i in 1..accounts.size-1
				puts i.to_s + " " + accounts[i-1].to_s
			end
			print "どの支出元を使用しますか？: "
			num = STDIN.gets.chomp.to_i

			if 0 < num and num < accounts.size
				break
			else
				puts "正しい数値を入力してください"
			end
		end
		@payment_account = [key[num-1].to_s, accounts[num-1].to_s]
		@payment_account
	end
end
