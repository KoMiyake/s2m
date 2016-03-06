# s2m

[大学生協](https://mp.seikyou.jp/mypage/) の購買履歴をMoneyForwardに登録するものです．
現在，入金履歴の登録には対応していません．

## Installation

まずはcloneしてください．

そして，cloneしたディレクトリ内で以下のコマンドを実行することによって，必要なgemがインストールされます

	$ bundle install 

## Usage

実行は，cloneしたディレクトリ内で
	
	$ ruby lib/s2m.rb

もしくは
	
	$ bin/console

とすることで実行することができます．

cloneしたディレクトリ直下に.envファイルを作成することによってログイン時の入力を省略することができます．

### .env

	MONEYFORWARD_ID   = 'XXXXXXXXXXXXXXX'
	MONEYFORWARD_PASS = 'XXXXXXXXXXXXXXX'
	SEIKYO_ID   = 'XXXXXXXXXXXXXXX'
	SEIKYO_PASS = 'XXXXXXXXXXXXXXX'

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

