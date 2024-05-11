
# 標準ライブラリ
import json
import os
import smtplib
import subprocess as sb
import sys 
from datetime import datetime, timezone, timedelta
from email.mime.text import MIMEText
from shutil import copy2
from io import BytesIO

# 外部ライブラリ
from flask import Blueprint, jsonify
from flask.globals import request
from flask.helpers import make_response


sys.path.append('..')  # '..' は親ディレクトリ
# プロジェクト内のファイル
from api.common import error_response
from api.db import *
from api.settings import * 

# 送られてくるキーのリスト
required_keys = ["UserID", "nickname", "email", "uploadTime",  "filename", "filepath", "code_filename", "code_filepath"]


#　csv、ソースコードをバイナリから復元する
def reconvert_from_binary(src_path:str, reconvert_file_path:str):
	print(src_path)
	with open(src_path, 'rb') as binary_file:
		binary_data = binary_file.read()

		# バイナリデータをバイトストリームに変換
		bytes_io = BytesIO(binary_data)
		with open( reconvert_file_path, "wb") as reconverted_file:
			# バイトストリームからCSVファイルに変換
			csv_data = bytes_io.getvalue()  # バイトデータを文字列に変換            
			reconverted_file.write(csv_data)

#回答csv <filename> <filePath>
#ソースコードファイル <code_filename> <code_filePath>

# DB から登録者を読み出し, 0リセット
def init_upload_num():
	all_db = session.query(db).all()
	session.close()
	upload_num_dict.clear()
	for data_db in all_db:
		upload_num_dict[data_db.name] = 0
	#print(f"Finish init: {upload_num_dict}")

# 提出回数をリセット
def clear_upload_num():
	for key in upload_num_dict:
		upload_num_dict[key] = 0
	#print(f"Finish clear: {Tpload_num_dict}")

def commit_error_msg_and_close_session(db_user, error_msg:str):
	db_user.error_msg = error_msg
	session.commit()
	session.close()

# 控えメールの送信
def send_mail(name:str, mail:str, csv:str="", code:str="", available_upload_num:int=4 ,is_correct_receive:bool=True, sent_error_msg:str = "" ):

	# 正しく提出を受理できたとき
	if is_correct_receive:
		mail_title = f"解答の受領のお知らせ"
		message = f"""
		{name} 様\n
		以下の内容で解答を受領しました。\n
		正答率や現在の順位は以下からご確認ください。\n
		https://ai-step.ec.t.kanazawa-u.ac.jp/competition_01\n
		解答受理日時: {datetime.now().strftime("%Y年%m月%d日 %H:%M:%S")}\n
		解答ファイル: {os.path.basename(csv)}\n
		ソースコードファイル: {os.path.basename(code)}\n

		本日の残り提出可能回数は{available_upload_num}です。これ以上提出する場合は翌日まで待ってから提出してください\n
		"""	
	
	# 正しく受理できなかったとき
	else:
		mail_title = f"解答再提出のお願い"
		message = f"""
		{name} 様\n
		申し訳ございません。解答を受理できませんでした。\n
		{sent_error_msg}\n
		再提出は以下のサイトからお願いします。\n\n
		{URL_MOODLE_UPLOAD}\n
		"""	
	
	msg = MIMEText(message, "plain")
	msg["Subject"] = mail_title
	msg["To"] = mail
	msg["From"] = FROM_EMAIL
	print(sent_error_msg)

	try:
		server = smtplib.SMTP(host=SMTP_HOST, port=SMTP_PORT)
		server.set_debuglevel(1) 
		server.ehlo("mylowercasehost")
		server.starttls()
		server.ehlo("mylowercasehost")
		server.login(FROM_EMAIL, EMAIL_PW)
		server.send_message(msg)
		#server.sendmail(FROM_EMAIL, [mail],  msg)
		server.quit()
		return 0
	except Exception as e:
		print(str(e))
		return 1

# 解答csvファイルとソースコードのアップロードと正答率計算
def upload(user_upload_data: str):

	data = json.loads(user_upload_data)
	missing_keys = []
	for key in required_keys:
		if data.get(key) == None:
			missing_keys.append(key)

	# 存在しないキーがあったら終了
	if len(missing_keys) != 0:
		print("以下の情報が不足しています")
		for missing_key in missing_keys:
			print(missing_key)
		return -1

	# JSON から id 取得
	uid = int(data["UserID"])
	name = data["nickname"]

	# 更新対象の DB のデータ選択
	db_user = session.query(db).filter(db.id == uid).one_or_none()
	print(db_user)
	# dbにuseridが存在しないなら登録
	if db_user is None:
			# idがないときは登録する
			db_user = db(
				id = uid,
				nickname = name,
				mail = data["email"],
				ans = "0.000",
				csv = os.path.join(ANS_DIR, name),
				code = os.path.join(ANS_DIR, name),
				bin_csv = data["filepath"],
				bin_code = data["code_filepath"],
				upload_unix = int(data["uploadTime"])
			)
			session.add(db_user)	
			session.commit()
	# 既にユーザが存在している時は提出済み
	# アップロード時間から再提出したのか判定。
	else:
		# 最新提出時間がDBの提出時間以下なら再提出はしていないので処理終了
		if (int(data["uploadTime"]) <= db_user.upload_unix):
			print("再提出はされていません")
			session.close()
			return 1

		# 再提出時はupload_unixを更新
		# このタイミングでunixを更新すると、フォーマットが違うなどでエラーがでて途中で終わっても再採点されない
		else:
			db_user.upload_unix = int(data["uploadTime"])
			session.commit()
			

	# 提出回数の確認
	try:
		if upload_num_dict[name] >= MAX_UPLOAD_NUM:
			error_msg =  "今日はこれ以上提出できません。再提出は翌日から可能です\n "
			commit_error_msg_and_close_session(db_user, error_msg) 
			return send_mail(name, data["email"], 0, is_correct_receive=False, sent_error_msg=error_msg)
	except:
		upload_num_dict[name] = 0

	# /ANS_DIR/nickname_名前_userid　のディレクトリ作成
	user_files_store_dir = os.path.join(ANS_DIR, f"{name}_{uid}")
	if not os.path.isdir(user_files_store_dir):
		print("makedir")
		os.mkdir(user_files_store_dir)

	# 解答csvファイルの一時保存
	binary_csv_path = os.path.join(MOODLE_DATA_DIR, (data["filepath"])) # 解答csvファイルのパス
	tmp_csv = os.path.join(user_files_store_dir, "tmp.csv")
	reconvert_from_binary(binary_csv_path, tmp_csv)

	# コマンド作成
	cmd_list = []
	cmd_list.append("stdbuf -o0")
	cmd_list.append(CAL_ANS)
	cmd_list.append(CORRECT_CSV)
	cmd_list.append(tmp_csv)
	cmd_list.append(str(CLASS_NUM))
	cmd = " ".join(cmd_list)

	# 正答率計算
	proc = sb.Popen("exec " + cmd, stdout=sb.PIPE, stderr=sb.PIPE, shell=True)
	try:
		res, err = proc.communicate()
	except IndexError as e:
		os.remove(tmp_csv)
		error_msg = "採点時にエラーが発生しました。再提出して下さい。"
		print(str(e))
		commit_error_msg_and_close_session(db_user, error_msg)
		return send_mail(name, data["email"], is_correct_receive=False, sent_error_msg=error_msg)

	err_str = err.decode("utf-8")
	if(err_str != ""):
		#os.remove(tmp_csv)
		if "行目の列数が2以外です。" in err_str or "全データのフォーマットが誤りです。" in err_str:
			commit_error_msg_and_close_session(db_user, err_str)
			print(err_str)
			return send_mail(name, data["email"], is_correct_receive=False, sent_error_msg=err_str)
		
		error_msg = "採点時にエラーが発生しました。再提出して下さい。"
		commit_error_msg_and_close_session(db_user, error_msg)
		return send_mail(name, data["email"], is_correct_receive=False, sent_error_msg=error_msg)

	try:
		ans_json = json.loads(res)
	except:
		session.close()
		os.remove(tmp_csv)
		error_msg = "採点時にエラーが発生しました。再提出して下さい。"
		commit_error_msg_and_close_session(db_user, error_msg)
		return send_mail(name, data["email"], is_correct_receive=False, sent_error_msg="採点時にエラーが発生しました。再提出して下さい。")

	ans = ans_json.get("ans")

	if(ans == ""):
		session.close()
		os.remove(tmp_csv)
		error_msg = "採点時にエラーが発生しました。再提出して下さい。"
		commit_error_msg_and_close_session(db_user, error_msg)
		return send_mail(name, data["email"], is_correct_receive=False, sent_error_msg=error_msg)


	# ディレクトリが消えていたら再生成
	if not os.path.isdir(user_files_store_dir):
		os.mkdir(user_files_store_dir)

	else:
		# 過去に提出している場合は保存してある前回の解答csvファイルとソースコードを削除
		for root, dirs, files in os.walk(user_files_store_dir):
			# directoryはないはずだが一応削除
			for dir in dirs:
				os.rmdir(os.path.join(root, dir))
			for file in files:
				# tmpファイルはスキップ
				if os.path.join(root, file) == tmp_csv:
					continue
				os.remove(os.path.join(root, file))

	# 解答csvファイル保存
	save_csv = os.path.join(user_files_store_dir, data["filename"])
	copy2(tmp_csv, save_csv)
	os.remove(tmp_csv)

	# ソースコード保存
	binary_code_path = os.path.join(MOODLE_DATA_DIR, data["code_filepath"]) # バイナリのソースコードのパス
	code_path = os.path.join(user_files_store_dir, data["code_filename"]) # 保存用ソースコードのパス
	reconvert_from_binary(binary_code_path, code_path)
	
	# DB の情報更新
	db_user.nickname = name
	db_user.ans = ans
	db_user.csv = save_csv
	db_user.code = code_path
	db_user.upload_unix = int(data["uploadTime"])
	db_user.error_msg = ""
	# unixをJSTの文字列に変換
	jst_timezone = timezone(timedelta(hours=9))  # timezoneを日本に
	jst_datetime = datetime.fromtimestamp(int(data["uploadTime"]))
	db_user.upload_date = jst_datetime
	session.commit()
	
	result_db = session.query(db).filter(db.nickname == name).one_or_none()
	if result_db is None:
		error_msg = "登録に失敗しました。再提出して下さい。"
		commit_error_msg_and_close_session(db_user, error_msg)
		return send_mail(name, data["email"], is_correct_receive=False, sent_error_msg=error_msg)

	# sessionのクロース	
	if session.is_active:
		session.close()

	# 控えメールの送信
	mail_res = send_mail(result_db.nickname, result_db.mail, csv=result_db.csv, code=result_db.code, available_upload_num=max(MAX_UPLOAD_NUM - upload_num_dict[result_db.nickname] - 1, 0))

	upload_num_dict[result_db.nickname] += 1

	return 1


if __name__ == "__main__":
		upload(sys.argv[1])

