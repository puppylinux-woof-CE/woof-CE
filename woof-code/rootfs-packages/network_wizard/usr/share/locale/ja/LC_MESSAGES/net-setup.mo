## Some rules used:
#- All localization variables start with L_
#- The (possible) second part is all-caps and indicates the type of widget etc.
#- The rest gives a rough description of what the message is (content/location)
#- They appear in the order in which they exist in the script -- not running order
#  +(except for the general ones that are used in different places)
#- Hard quotes ('') should be kept when used and variables ($INTERFACE) not touched

# update: Mar. 19th '09: expanded the "function: giveNoWPADialog" section
# update: Mar. 29th: add "function: waitForPCMCIA" section

#  encode ja_JP.utf-8
#  translator himajin,YoN 20081107
# fixed for Japanese Xdialog, Shino's Bar 20090430

##  The command to use with the "help" button ("net_setup" can be changed for a 
##+ different help file, eg. "net_setup.de", for a file /usr/share/doc/net_setup.de.htm)
HELP_COMMAND="man 'net_setup'"

############### General text ###############
L_TITLE_Puppy_Network_Wizard="Puppy Network Wizard"	#"Puppy ネットワーク ウィザード"
L_TITLE_Network_Wizard="Network Wizard"
L_TITLE_Netwiz_Static_IP="Puppy ネットワーク ウィザード: 固定 IP"
L_BUTTON_Exit="終了"
L_BUTTON_Save="保存"
L_BUTTON_Load="読み込"
L_BUTTON_Unload="切り離す"
L_BUTTON_Back="戻る"
L_BUTTON_Blacklist="ブラックリスト"
L_BUTTON_No="No"

############### end General text ###############



############### net-setup.sh ###############
# function: refreshMainWindowInfo
L_LABEL_Interface_Tree_Header="インターフェース|タイプ|モジュール|デバイスの種類"

L_ECHO_No_Interfaces_Message="アクティブなネットワークインターフェースを見つけられません.

PCに１つ以上のネットワークアダプタ（インターフェース）がありそれらを使いたいなら、ドライバ・モジュールを読み込む必要があります。パピーが起動する時に自動的に検出され、正しいドライバーが読み込れると思いますが、この場合はそうなりませんでした。でも大丈夫、手動でできます！"
L_ECHO_One_Interface_Message="パピーはコンピュータ内に次のネットワークインターフェースを見つけました。しかしまだ設定する必要があります。
インターフェースのテストや設定をするには、そのボタンをクリックして下さい。"
L_ECHO_Multiple_Interfaces_Message="パピーはコンピュータ内に次のネットワークインターフェースを見つけました。しかしまだ設定する必要があります。
インターフェースのテストや設定をするには、そのボタンをクリックして下さい。"

# function: buildMainWindow
L_FRAME_Interfaces="インターフェース"
L_FRAME_Network_Modules="ネットワークモジュール"

# function: showLoadModuleWindow
L_TITLE_Load_Network_Module="ネットワークモジュールの読み込"
L_NOTEBOOK_Modules_Header="モジュール|Ndiswrapper|さらに"

L_TEXT_Select_Module_Tab="以下にハードウェアに適合する(まだ読み込まれていない）モジュールがあれば、そのモジュールを選択して「読み込」ボタンを押して下さい。
モジュールがなかったり、自信がなかったら「さらに」タブへ行って下さい。"
L_LABEL_Module_Tree_Header="モジュール|タイプ|種類"

L_TEXT_Ndiswrapper_Tab="<b>Ndiswrapper</b> はWindowsのドライバを「ラッピング」してLinuxで使えるようにするメカニズムです。

使い方は、Windowsドライバ用の情報ファイル(.INF)のある場所を知る事が必要なだけです(普通は、Windowsのインストールされているドライバディレクトリにあります)。

注意。Ndiswrapper は Windows Vistaドライバでは<b>動きません</b>。
"
L_BUTTON_Use_Ndiswrapper="Ndiswrapperを使う"

L_TEXT_More_Tab="一覧にないモジュールを選択するには「<b>特定</b>」をクリックするか、パラメータを付けてモジュールを指定します（ISAカードには必須です。下の例をご覧下さい）。
現在読み込まれたモジュールを切り離して(別のモジュールを読み込めるように)するには「<b>切り離し</b>」をクリック。
一覧の全モジュールを組込には「 <b>自動認識</b> 」をクリック。

例1: ne io=0x000, 
例2: arlan  io=0x300 irq=11
(例1 はほとんどのISAカードで動きます。そしていくつかの IO と IRQ の自動認識もします)"
L_BUTTON_Specify="特定"
L_BUTTON_Autoprobe="自動認識"

L_TOPMSG_Load_Module_None_Selected="モジュールの読み込を報告: モジュールが選択されていません"
L_TOPMSG_Load_Module_Cancel="モジュールのロ読み込を報告: モジュールが読み込まれていません"

L_MESSAGE_One_New_Interface="新しいインターフェースが見つかりました"
L_MESSAGE_Multiple_New_Interfaces="以下の新しいインターフェースが見つかりました"

L_FRAME_New_Interfaces="新しいインターフェース"
L_LABEL_New_Interfaces_Tree_Header="インターフェース|タイプ|モジュール|デバイスの種類"
L_TEXT_New_Interfaces_p1=" '保存' ボタンをクリックして選択を保存すると, 自動的に読み込まれます"
L_TEXT_New_Interfaces_p2="起動時に
\\キャンセルをクリックすると新しいインターフェースの設定に戻ります."

L_TEXT_No_New_Interfaces1="新しいインターフェースは検出されませんでした."
L_TEXT_No_New_Interfaces2=" '切り離す' ボタンをクリックすると新しいインターフェースを切り離してその他を試します."

L_TITLE_New_Module_Loaded="新しいモジュールが読み込まれました"
L_TEXT_New_Module_Loaded="以下のモジュールが読み込まれます:"

L_TOPMSG_New_Module_Save="新しいモジュールの情報を保存"
L_TOPMSG_New_Module_Unload="新しいモジュールの切り離す"
L_TOPMSG_New_Module_Cancelled="キャンセル"

L_TOPMSG_Load_Module_None_Loaded="モジュールの読み込を報告: モジュールは読み込まれませんでした"

# function: tryLoadModule
L_TITLE_Netwiz_Hardware="Puppy ネットワーク ウィザード: ハード"
L_MESSAGE_Driver_Loaded="ドライバはすでに読み込まれています。\nでも実際に正常に動いていると言う事ではありません！\n「OK」をクリック後、新しいインターフェースが検出されたかどうか\n確認して下さい。"
L_MESSAGE_Driver_Success_p1="モジュールの"
L_MESSAGE_Driver_Success_p2="読み込みに成功。
但し実際に動いていることを意味しません!
OKをクリックした後, 新しいインターフェースが
認識されているか見て下さい。"

L_MESSAGE_Driver_Failed_p1="読み込み中 "
L_MESSAGE_Driver_Failed_p2="以下のメッセージと共に失敗:
"
L_MESSAGE_Driver_Failed_p3="おそらく違うドライバです。
"

# function: giveAcxDialog
L_TEXT_Acx_Module_p1="あなたの選択したモジュールが使うモジュール"
L_TEXT_Acx_Module_p2="
このモジュールを切り離すとシステムが不安定になり、Ndiswrapper は、ほとんど動かなくなる事が知られています。

モジュールをブラックリストして再起動する事が推奨されます。そうすると Ndiswrapper は心配無く使えます。

モジュールをブラックリストしますか、それには再起動する必要があります。あるいは、あえて切り離しを試してみますか？
"

# function: askWhichInterfaceForNdiswrapper
L_TEXT_Ask_Which_Interface_For_Ndiswrapper="<b>Ndiswrapper を使える前に1つ:</b>
あなたのネットワークカードは一度に1つのドライバでしか使えません。これは、すでにそれを使っているドライバがあれば(すなわち、メインダイアログにマッチするインターフェースがあれば)、Ndiswrapper を使える前にそのドライバを切り離する必要があります。

そうするためには、関係あるインターフェースにマッチするボタンを押すだけです。もしハードウェアにマッチするインターフェースがなければ、「なし」を押して下さい。
"
L_BUTTON_None="なし"

L_MESSAGE_Remove_Module_Failed_p1="エラー!
モジュールの切り離しに失敗"
L_MESSAGE_Remove_Module_Failed_p2="
以下のエラー:"

# function: loadNdiswrapperModule
L_MESSAGE_Blacklist_Nativemod_p1="読み込まれているモジュールは"
L_MESSAGE_Blacklist_Nativemod_p2="ndiswrapperが働かせるために
切離さなくてはいけません
ブート時に読み込まれないよう
このモジュールを
ブラックリストに追加しますか 
注, ブートマネージャー（システムメニュー参照)を起動して
いつでも行えます"

# function: loadSpecificModule
L_TITLE_Load_A_Module="モジュール読み込み"
L_TEXT_Load_A_Module="特定のモジュールの名前を入力して下さい
(パラメータを追加できますが、タブ文字は入力しないで下さい)。"

# function: autoLoadModule
L_MESSAGE_Success_Loading_Module_p1="モジュールの読み込に"
L_MESSAGE_Success_Loading_Module_p2="成功。これは実際に働いている事を意味しません！
「OK」をクリック後、 新しいアクティブなインターフェースが設定を始めたらメインウィンドウに戻って下さい。

注意: モジュールの読み込はできるけれども、見つからない。これはネットワークアダプタが実際に動いていないのです。この場合、もう一度自動認識を試して下さい。 
このスクリプトは前回の試みを記憶しています(このスクリプトを終了するまで)。そしてそれを飛ばします。
見つからない場合は、Puppy Discussion Forum に知らせて下さい！"

L_MESSAGE_No_Module_Loaded="読み込みに成功したモジュールはありません。

注 これらのモジュールは既に読み込まれています:"

# function: offerToBlacklistModule
L_TEXT_Blacklist_Module_p1="モジュール"
L_TEXT_Blacklist_Module_p2="除去に成功。

ブート時に読み込まれないよう
ブラックリストにしますか？
"

# function: unloadSpecificModule
L_MESSAGE_No_Loaded_Items="エラー!
現在ネットワークモジュールが読み込まれていないようです...
"

L_TITLE_Unload_A_Module="モジュールの切り離し"
L_TEXT_Unload_A_Module="切り離したい
モジュールを選択し, '切り離す'を押して下さい..."
L_COMBO_Module="モジュール:"

# function: findLoadedModules
L_PROGRESS_Checking_Loaded_Modules="読み込んだモジュールをチェック"

# function: testInterface
L_MESSAGE_Failed_Raise_Interface_p1="エラー!
Failed to raise interface"
L_MESSAGE_Failed_Raise_Interface_p2="失敗したコマンド:"
L_MESSAGE_Failed_Raise_Interface_p3="帰ってきたエラー:"

L_PROGRESS_Testing_Interface="インターフェースのテスト"

L_TOPMSG_Report_On_Test='$INTERFACE 接続のテストレポート:'
L_TOPMSG_Unplugged_Wireless="'ワイヤレスネットワークに接続できません'
ワイヤレスネットワークが可能かどうか、正しいワイヤレス
パラメータがあたえられているか確認して下さい。"
L_TOPMSG_Unplugged_Wired="'ワイヤレスネットワークに接続できません'
ネットワークが可能かどうか、イーサネット
ケーブルが接続されているか確認して下さい。"
L_TOPMSG_Network_Alive="'パピーは生きているネットワークを見つけられました'
IPアドレスの取得に進むことができます。"

# function: showConfigureInterfaceWindow
L_TOPMSG_Configuration_Cancelled='$INTERFACE ネットワークの設定をキャンセルしました!'
L_BUTTON_Done="完了"

L_TOPMSG_Configuration_Unsuccessful='$INTERFACE ネットワークの設定に失敗 !'
L_TOPMSG_Configuration_Offer_Try_Again="再試行、別のインターフェースを試すには「戻る」をクリック、今のところやめるには「完了」をクリックして下さい。"
L_TOPMSG_Configuration_Successful='$INTERFACE ネットワークの設定に成功!'
L_TOPMSG_Configuration_Offer_To_Save="
この設定を保存しますか?

次回の起動にこの設定を保存しておきたいなら: 'Yes' をクリック。
このセッションだけにこの設定を使いたいだけなら: 'No' をクリック。"
L_TOPMSG_Configuration_Offer_To_Finish="
これ以上セットアップや設定するインターフェースがなければ、「Done」をクリックして終了して下さい。"
L_TOPMSG_Configuration_Not_Saved="次回の起動用に設定は保存されませんでした。

これ以上セットアップや設定するインターフェースがなければ、「Done」をクリックして終了して下さい。"

# function: buildConfigureInterfaceWindow
L_TITLE_Configure_Interface='$INTERFACE $INTERFACE ネットワークを設定'
L_FRAME_Test_Interface="インターフェースをテスト"
L_BUTTON_Test_Interface='$INTERFACE をテスト'
L_FRAME_Configure_Interface="インターフェースを設定"
L_BUTTON_Auto_DHCP="自動 DHCP"
L_BUTTON_Static_IP="固定 IP"

# function: initializeConfigureInterfaceWindow
L_TOPMSG_Initial_Lets_try="OK、 設定しましょう"
L_TESTMSG_Initial_p1="テストできます。もし"
L_TESTMSG_Initial_p2="が「生きている」ネットワークに接続されていれば、
接続されている事を確認後、インターフェースを設定できます。"
L_DHCPMSG_Initial="ネットワークを設定する最も簡単な方法は、DHCPサーバ（通常、ネットワークによって提供されます）を用いることです。これは、パピーが起動時にサーバに問い合わせ、自動的にIPアドレスを割り当てられる事を可能にします。「dhcpcd」クライアントデーモンプログラムが起動され、ネットワークアクセスが自動的に起こります。"
L_STATICMSG_Initial="DHCPサーバが利用できないならば、固定IPを設定することで、手動ですべてしなければなりません。しかし、このスクリプトは、それを簡単にします。"

L_FRAME_Configure_Wireless="ワイヤレスネットワークの設定"
L_TEXT_Configure_Wireless_p1="パピーは見つけました"
L_TEXT_Configure_Wireless_p2="は、ワイヤレスインターフェースです。
ワイヤレスネットワークに接続するには、最初に「ワイヤレス」ボタンをクリックして、ワイヤレスネットワークパラメータをセットしなければなりません。それから、DHCPまたはStatic IPでIPアドレスをそれに割り当てて下さい(下記参照)。"
L_BUTTON_Wireless="ワイヤレス"

# function: configureWireless
L_TOPMSG_Wireless_Config_Failed_p1="ワ イ ヤ レ ス 設 定"
L_TOPMSG_Wireless_Config_Failed_p2="は失 敗 !
異なったプロファイルを使おうとしています. "
L_TOPMSG_Wireless_Config_Cancelled_p1="ワ イ ヤ レ ス 設 定"
L_TOPMSG_Wireless_Config_Cancelled_p2="は キ ャ ン セ ル !
ワイヤレスネットワークへ接続するために使うプロファイルを選んで下さい. "

# function: buildStaticIPWindow
L_TITLE_Set_Static_IP="固定 IP をセット"
L_TEXT_Set_Static_IP="固定 IP を入力:
- ルータを使うならば、その値のためにそのステータスページをチェックして下さい。
- 直接モデムに接続するならば、ご自分のISPからその値を得ることが必要です。
（2台のコンピュータを直接接続するには：IPとネットマスク以外は、
全て 0.0.0.0 にセットして下さい）

ドットで区切られた4つの10進法の書式だけを使って下さい (xxx.xxx.xxx.xxx)。
他のフォーマットは認められません。
"
L_FRAME_Static_IP_Parameters="固定 IP パラメータ"
L_ENTRY_IP_Address="IP アドレス:"
L_ENTRY_Net_Mask="ネットマスク:"
L_ENTRY_Gateway="ゲートウェイ:"
L_FRAME_DNS_Parameters="DNS パラメータ"
L_ENTRY_DNS_Primary="プライマリ:"
L_ENTRY_DNS_Secondary="セカンダリ:"

# function: validateStaticIP
L_ERROR_Invalid_IP="不正な IP アドレス"
L_ERROR_Invalid_Netmask="不正な ネットマスク"
L_ERROR_Invalid_Gateway="不正な ゲートウェイアドレス"
L_ERROR_Invalid_DNS1="不正な DNS server 1 アドレス"
L_ERROR_Invalid_DNS2="不正な DNS server 2 アドレス"

L_MESSAGE_Bad_addresses="エラー!
提供されたアドレスのいくつかが無効です。"

L_MESSAGE_Bad_Netmask="警告:
ネットマスクがネットワーク・アドレス・クラスと対応しません。

それが正しいと確信していますか?"

L_MESSAGE_Bad_Gateway_p1="エラー!
ゲートウェイ"
L_MESSAGE_Bad_Gateway_p2="は、このネットワーク上にありません。
(アドレス、ゲートウェイまたはネットマスクを間違って入力したかも知れません)。
"

# function: setupStaticIP
L_MESSAGE_Route_Set='デフォルトルートは $GATEWAY を通してセットしました。'
L_MESSAGE_Route_Failed_p1="エラー!
通してデフォルトルートを設定できませんでした。"
L_MESSAGE_Route_Failed_p2="パピーがこれをしようとした事に注意して下さい:"
L_MESSAGE_Route_Failed_p3="
そして、以下のエラーメッセージを得ました:"

L_MESSAGE_Ifconfig_Failed_p1="エラー! インターフェースの設定に失敗。

パピーはちょうどこれをしようとしました。:"
L_MESSAGE_Ifconfig_Failed_p2="そして、以下のエラーメッセージを得ました:"
L_MESSAGE_Ifconfig_Failed_p3="
ご自分のシステムには、これが間違っていると思うなら、
働く他の何かを見つけ出す事ができます。私たちが
ウィザードを改良できるよう、フォーラムに投稿して下さい。"

# function: saveNewModule
L_TOPMSG_Module_Saved_p1="モ ジ ュ ー ル"
L_TOPMSG_Module_Saved_p2="は /etc/ethernetmodules に 記 録 さ れ ま し た。
パピーは起動時にこれを読み込みます。"

# function: unloadNewModule
L_TOPMSG_Module_Unloaded_p1="モ ジ ュ ー ル"
L_TOPMSG_Module_Unloaded_p2="は 切 り 離 さ れ ま し た。
さらに、"
L_TOPMSG_Module_Unloaded_p3="/etc/ethernetmodules (もしあれば)から削除されました。"

# function: setDefaultMODULEBUTTONS
L_TEXT_Default_Module_Buttons="ネットワークアダプタのドライバモジュールが読みこまれていないように見えたり、あるいは違うドライバ(NdiswrapperのWindowsドライバなど)が欲しいならば、「モジュールの読み込」ボタンをクリックして下さい。"
L_BUTTON_Load_Module="モジュールの読込"

# function: findInterfaceInfo
L_INTTYPE_Wireless="ワイヤレス"
L_INTTYPE_Ethernet="イーサネット"
L_INFO_Eth_Firewire="ファイヤーワイヤー越えイーサネット"

L_TOPMSG_Initial="やぁ,ネットワークの設定は簡単じゃないけど, 頑張っていこう!"

############### end net-setup.sh ###############


############### wag-profiles.sh ###############
L_FRAME_Progress="進捗状態"
L_BUTTON_Abort="中止"
L_BUTTON_Retry="やり直し"

# function: setupDHCP
L_TEXT_Dhcpcd_Progress='DHCPサーバーに接続中... タイムアウトは $MAX_TIME 秒.'

# function: giveNoWPADialog
L_TEXT_No_Wpa_p1="注意: あなたの選択したインターフェースが使うモジュール "
L_TEXT_No_Wpa_p2="は、WPA 暗号化をサポートしていません."
L_BUTTON_Add_WPA="リストに追加"
L_TEXT_No_Wpa_Ask="しかし確かにそれが WPA をサポート <i>している</i> と分かっているか、あるいは動くかどうかテストしたいならば（ただ１つの違いは設定ダイアログにたくさんのオプションが提示される事です）、  '$L_BUTTON_Add_WPA' ボタンをクリックして下さい。これは将来使うために設定ファイルにモジュールを追加します。 "
L_TEXT_Wpa_Add_p1="以下の詳細は設定ファイル "
L_TEXT_Wpa_Add_p2="に追加されます。"
L_ENTRY_Wpa_Add_Module="モジュール:"
L_ENTRY_Wpa_Add_WEXT="wpa_supplicant ドライバ:"

# function: buildProfilesWindow
L_TEXT_Profiles_Window="使用するネットワークのプロファイルを選んでください。
新しいプロファイルを作るために, 既存のネットワークをスキャンした中から設定したいものを選んで始めます。 
新しく作られたプロファイルを使うためには <b>保存</b> ボタンを押してください。"
L_BUTTON_Scan="スキャン"
L_FRAME_Load_Existing_Profile="プロファイルの読み込み"
L_TEXT_Select_Profile="読み込むプロファイルの選択:"
L_FRAME_Edit_Profile="プロファイルの編集"
L_TEXT_Encryption="暗号化:    "
L_BUTTON_Open="公開"
L_TEXT_Profile_Nmae="プロファイル
名:   "
L_TEXT_Essid="ESSID:    "
L_TEXT_Mode="モード:"
L_CHECKBOX_Managed="管理"
L_CHECKBOX_Adhoc="アドホック "
L_TEXT_Security="セキュリティ: "
L_CHECKBOX_Open="暗号化なし"
L_CHECKBOX_Restricted="制限"
L_BUTTON_Delete="削除"
L_BUTTON_Use_Profile="このプロファイルを使う"
L_BUTTON_New_Profile="新しいプロファイル"

# function: setWepFields
L_TEXT_Key="キー:"

# function: setWpaFields
L_TEXT_AP_Scan="AP スキャン:"
L_CHECKBOX_Hidden_SSID="Hidden SSID"
L_CHECKBOX_Broadcast_SSID="Broadcast SSID"
L_CHECKBOX_Driver="ドライバー"
L_TEXT_Shared_Key="暗号化キー:"

# function: setAdvancedFields
L_LABEL_Advanced="高度"
L_LABEL_Basic="基本"
L_TEXT_Frequency="周波数:"
L_TEXT_Channel="チャンネル:"
L_TEXT_AP_MAC="アクセスポイント
     MAC:"

# function: saveProfiles
L_MESSAGE_Bad_Profile="エラー!
そのプロファイルに関連付けられているネットワークはありません.
ワイヤレススキャンを実行し、ネットワークを選択して
そのプロファイルを作成して下さい。"

# function: getWpaPSK
L_MESSAGE_Bad_PSK="エラー!
wpa_passphrase はあなたのキーとSSIDから
PSK の作成に失敗しました！
この事をフォーラムにレポートして下さい。そうすれば
私達は問題を見付るべく試してみます.
"

# function: cleanUpInterface
L_MESSAGE_Failed_To_Raise_p1="エラー!
インターフェース "
L_MESSAGE_Failed_To_Raise_p2="の立ち上げに失敗。
失敗したコマンド:"
L_MESSAGE_Failed_To_Raise_p3="帰って来たエラー:"

# function: useIwconfig / useWlanctl
L_MESSAGE_Configuring_Interface_p1="インターフェース "
L_MESSAGE_Configuring_Interface_p2=" 
をこのネットワークへ設定中 "

# function: validateWpaAuthentication
L_ECHO_Status_p1="時間: "
L_ECHO_Status_p2="	状況: "

# function: useWpaSupplicant
L_MESSAGE_No_Wpaconfig_p1="エラー!
wpa_supplicant 設定ファイルが見つかりません:"
L_MESSAGE_No_Wpaconfig_p2="
注 使用する前にそのプロファイルを保存する必要があります！"

L_TEXT_WPA_Progress_p1="取得中 "
L_TEXT_WPA_Progress_p2=" 接続先 "
L_TEXT_WPA_Progress_p3="...(30 sec. タイムアウト)"

L_ECHO_Starting="開始"
L_ECHO_Initializing_Wpa="wpa_supplicant を初期化中"
L_MESSAGE_TKIP_Failed="WPA/TKIP接続に失敗！AESでやり直してみますか？"
L_MESSAGE_WPA_Failed="WPA 接続を確立できません"
L_BUTTON_Details="詳細"

L_FRAME_Connection_Info="接続情報"
L_FRAME_wpa_cli_Outeput="出力 "
L_BUTTON_Refresh="リフレッシュ"

# function: waitForPCMCIA
L_PROGRESS_Waiting_For_PCMCIA="PCMCIA デバイスが解決するのを待っています"

# function: showScanWindow
L_PROGRESS_Scanning_Wireless="ワイヤレス ネットワークをスキャン中"

# function: buildScanWindow
L_SCANWINDOW_Encryption="暗号化:"
L_SCANWINDOW_Channel="チャンネル:"
L_SCANWINDOW_Frequency="周波数:"
L_SCANWINDOW_AP_MAC="AP MAC:"
L_SCANWINDOW_Strength="強度:"

L_TEXT_Scanwindow="利用可能なネットワークを選択してください。
	その上にマウスカーソルを重ねると詳細が見られます。"

# function: createNoNetworksDialog
L_TEXT_No_Networks_Detected="検出されたネットワークはありません.

もしかしてルータのスイッチがオフ?
ノートパソコンにあるワイヤレスのスイッチをオンに?"

# function: createRetryScanDialog
L_TEXT_No_Networks_Retry=" ネットワークは検出されませんでした. 
 再度スキャンしてみますか?
"

# function: createRetryPCMCIAScanDialog
L_TEXT_No_Networks_Retry_Pcmcia="検出されたネットワークはありません。
しかし、あなたは PCMCIA デバイスを使用しているようです。 
スキャンするためにはリセットする必要があるかも知れません。
カードをリセットして再度スキャンしてみますか?
"

# function: buildPrismScanWindow (many used from buildScanWindow above)
L_SCANWINDOW_Hidden_SSID="(隠し SSID)"
L_TEXT_Prism_Scan="利用可能なネットワークを選択してください。
	その上にマウスカーソルを重ねると詳細が見られます。"

# function: setupScannedProfile
L_TEXT_Provide_Key=""

############### end wag-profiles.sh ###############



############### ndiswrapperGUI.sh ###############
L_TITLE_Netwiz_Ndiswrapper="Puppy ネットワーク ウィザード: Ndiswrapper"
L_TEXT_Ndiswrapper_Chooser="ドライバ情報ファイル (.INF)を選んで下さい."

L_MESSAGE_Bad_Inf_Name="
エラー!
 .infを末尾にして
もう一度.
"

############### end ndiswrapperGUI.sh ###############


############### rc.network ###############
L_TITLE_Success="成功"
L_MESSAGE_Success="成功"
L_TITLE_Failure="失敗"
L_MESSGAE_Failed="失敗しました"

L_MESSAGE_Failed_To_Connect="
  ネットワークに繋がりません。
  まだネットワークインターフェースの設定を行っていないのなら、
  ネットワーク ウィザードで設定してください。
  (デバッグメッセージは /tmp/network-connect.log にあります)"
  
############### end rc.network ###############
