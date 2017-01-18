# s2m

[大学生協](https://mp.seikyou.jp/mypage/) の購買履歴をMoneyForwardに登録するものです．


## Installation

まずはcloneしてください．

そして，cloneしたディレクトリ内で以下のコマンドを実行することによって，必要なgemがインストールされます．

	$ bundle install 

また，nkfコマンドが必要なので，それもインストールしてください．

	$ sudo apt-get install nkf

### .env
cloneしたディレクトリ直下に.envファイルを作成して，以下の書式にしたがってログイン情報を入力してください．

	MONEYFORWARD_ID   = 'XXXXXXXXXXXXXXX'
	MONEYFORWARD_PASS = 'XXXXXXXXXXXXXXX'
	SEIKYO_ID   = 'XXXXXXXXXXXXXXX'
	SEIKYO_PASS = 'XXXXXXXXXXXXXXX'

## Usage

実行は，cloneしたディレクトリ内で
	
	$ ruby lib/s2m.rb

もしくは
	
	$ bin/console

とすることで実行することができます．

初回の実行では生協の口座について質問されますが，以降の実行では質問されません．

## Notice
このシステムでは入金処理にも対応していますが，この処理は財布からの出金についてはMoneyforwadに反映されません．

(財布から出るお金と生協のカードに入金するお金が必ずしも一致するとは限らないため)

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

