require "active_support"
require "yaml"

# --------------------------------------------------------------------------------
#  定数など
#

CONFIG_PATH = File.expand_path('../../config/config.yml', __FILE__)


# --------------------------------------------------------------------------------
#  Initialize
#

# 設定ファイルなどを読み込む
config           = YAML.load_file(CONFIG_PATH)

member_list_path = File.expand_path(config[:member_list_path])
secret_key_path  = File.expand_path(config[:secret_key_path])

# ファイルが存在しなかったら生成する
File.open(member_list_path, "w") unless File.exist?(member_list_path)
File.write(secret_key_path, SecureRandom::hex(128)) unless File.exist?(secret_key_path)

# 読み込む
member_list      = YAML.load_file(member_list_path)
member_list = {} unless member_list # ファイルが空だと false になるので
secret_key       = File.read(secret_key_path)


# Encrypter の準備
encryptor = ::ActiveSupport::MessageEncryptor.new(secret_key, cipher: "aes-256-cbc")


# --------------------------------------------------------------------------------
#  Main
#

# アクションを選択させる
puts <<-"EOS"
Action?
1: Register
2: Show
0: Quit
EOS
print "> "

# 振り分ける
case gets.chomp
when "1"
  # 登録
  puts "Name?"
  print "> "
  name = gets.chomp

  puts "Bluetooth Address?"
  print "> "
  address = gets.chomp

  member_list[name] = encryptor.encrypt_and_sign(address)

  File.open(member_list_path, "w") { |f| YAML.dump(member_list, f)}
  puts "Done."
when "2"
  # リストを示す
  puts "(Name: Bluetooth address)"
  member_list.each do |k, v|
    puts "#{k}: #{encryptor.decrypt_and_verify(v)}"
  end
when "0"
  exit
else
  puts "Invalid input."
  abort
end
