# coding: utf-8
require 'mechanize'
require 'openssl'
require 'nokogiri'
require 'io/console'

class Seikyo
	def initialize
		@agent = Mechanize.new{|a| a.ssl_version, a.verify_mode = 'SSLv3', OpenSSL::SSL::VERIFY_NONE}
		@login_url = 'https://mp.seikyou.jp/mypage/Static.init.do'
	end

	def login
		begin
			id = ENV['SEIKYO_ID']
			pass = ENV['SEIKYO_PASS']

			puts "Login SEIKYO..."
			if id == nil
				print "ID: "
				id = STDIN.gets.chomp
			end

			if pass == nil
				print "Pass: "
				pass = STDIN.noecho(&:gets).chomp
				puts ""
			end

			@agent.get(@login_url) do |page|
				page.form_with(:name => 'loginForm') do  |form|
					form.field_with(:name => "loginId").value = id 
					form.field_with(:name => "password").value = pass 
				end.click_button
			end
			sleep 1

			if not login?
				puts "ログインに失敗しました"
				exit
			end
		end while not login?
	end

	def login?
		return !@agent.page.search("//img[@alt=\"ログイン中\"]").empty?
	end

	def analysis_cvs(file_name)
		LARGE_CATEGORY_ID_OF_FOOD_EXPENSES = 11
		MIDDLE_CATEGORY_ID_OF_EATING_OUT = 42

		payments = []
		# 文字コードの問題でcvsファイルが読み込めないので，nkfコマンドでUTF-8に直している
		system("nkf -w --overwrite " + file_name)

		File.open(file_name) do |file|
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

		File.delete file_name

		payments
	end

	# 2ヶ月分の購買履歴をとってくる
	def get_payment_history
		puts "購買履歴の取得をします..."
		form =  @agent.page.form("menuForm")
		form.id = "ALL_HISTORY"
		form.action = "/mypage/Menu.change.do" + "?pageNm=" + "ALL_HISTORY"
		@agent.submit(form)
		sleep 1

		file_name = create_file_name()

		form = @agent.page.form("AllHistoryFormCsvDownload")
		@agent.submit(form).save_as(file_name)

		payments = analysis_cvs(file_name)


		@agent.get("https://mp.seikyou.jp/mypage/Menu.change.do")
		sleep 1
		form =  @agent.page.form("menuForm")
		form.id = "ALL_HISTORY"
		form.action = "/mypage/Menu.change.do" + "?pageNm=" + "ALL_HISTORY"
		@agent.submit(form)
		sleep 1

		form = @agent.page.form_with(:name => "AllHistoryFormChangeDate")
		form.field_with(:name => "rirekiDate").options.first.select
		@agent.submit(form)
		sleep 1

		file_name = create_file_name()

		form = @agent.page.form("AllHistoryFormCsvDownload")
		@agent.submit(form).save_as(file_name)

		payments = payments + analysis_cvs(file_name)

		payments
	end

	def create_file_name
		begin
			file_name = (0...8).map{ (65 + rand(26)).chr }.join
		end while File.exist? file_name
		file_name
	end
end
