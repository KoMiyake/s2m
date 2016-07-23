# coding: utf-8
require 'mechanize'
require 'openssl'
require 'nokogiri'
require 'io/console'

class Seikyo
	LARGE_CATEGORY_ID_OF_FOOD_EXPENSES = 11
	MIDDLE_CATEGORY_ID_OF_EATING_OUT = 42

	def initialize
		@agent = Mechanize.new{|a| a.ssl_version, a.verify_mode = 'SSLv3', OpenSSL::SSL::VERIFY_NONE}
		@login_url = 'https://mp.seikyou.jp/mypage/Static.init.do'
	end

	public
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

	def login?
		begin
			return !@agent.page.search("//img[@alt=\"ログイン中\"]").empty?
		rescue
			false
		end
	end

	private
	def analysis_cvs(cvs_file)
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
					day.year = day.year-1
				end

				product = data[2]
				price = data[4]

				payments << Payment.new(day, product, price, LARGE_CATEGORY_ID_OF_FOOD_EXPENSES, MIDDLE_CATEGORY_ID_OF_EATING_OUT)
			end
		end

		File.delete cvs_file

		payments
	end

	# 2ヶ月分の購買履歴をとってくる
	public
	def get_payment_history
		goto_history_page
		payments = all_history_form_csv_download 

		goto_last_month_history_page
		payments = payments + all_history_form_csv_download

		payments
	end

	private
	def goto_last_month_history_page
		goto_history_page

		form = @agent.page.form_with(:name => "AllHistoryFormChangeDate")
		form.field_with(:name => "rirekiDate").options.first.select
		@agent.submit(form)
		sleep 1
	end

	private
	def goto_history_page
		@agent.get("https://mp.seikyou.jp/mypage/Menu.change.do")
		sleep 1
		
		form =  @agent.page.form("menuForm")
		form.id = "ALL_HISTORY"
		form.action = "/mypage/Menu.change.do" + "?pageNm=" + "ALL_HISTORY"
		@agent.submit(form)
		sleep 1

	end

	private
	def all_history_form_csv_download
		cvs_file = create_file_name()

		form = @agent.page.form("AllHistoryFormCsvDownload")
		@agent.submit(form).save_as(cvs_file)

		analysis_cvs(cvs_file)
	end

	private
	def create_file_name
		begin
			file_name = "/tmp/" + (0...8).map{ (65 + rand(26)).chr }.join
		end while File.exist? file_name
		file_name
	end
end
