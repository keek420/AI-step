# 標準ライブラリ
import json
import os
import smtplib
import subprocess as sb
from datetime import datetime
from email.mime.text import MIMEText
from shutil import copy2

# 外部ライブラリ
from flask import Blueprint, jsonify
from flask.globals import request
from flask.helpers import make_response

# プロジェクト内のファイル
from .common import error_response
from .db import *
from .settings import	(ANS_DIR, CAL_ANS, CLASS_NUM, CORRECT_CSV, EMAIL_PW,
						 FROM_EMAIL, MAX_UPLOAD_NUM, SMTP_HOST, SMTP_PORT,
						 upload_num_dict)

# 設定
app = Blueprint("upload", __name__)

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
	#print(f"Finish clear: {upload_num_dict}")

# 控えメールの送信
def send_mail(name:str, mail:str, csv:str, code:str, ):
	mail_title = f"解答の受領のお知らせ"
	message = f"""
	{name} 様\n
	以下の内容で解答を受領しました。\n
	正答率や現在の順位は以下からご確認ください。\n
	https://ai-step.ec.t.kanazawa-u.ac.jp/competition_01\n
	解答提出日時: {datetime.now().strftime("%Y年%m月%d日 %H:%M:%S")}\n
	解答ファイル: {os.path.basename(csv)}\n
	ソースコードファイル: {os.path.basename(code)}\n
	"""

	msg = MIMEText(message, "plain")
	msg["Subject"] = mail_title
	msg["To"] = mail
	msg["From"] = FROM_EMAIL

	try:
		server = smtplib.SMTP(SMTP_HOST, SMTP_PORT)
		server.ehlo()
		server.starttls()
		server.login(FROM_EMAIL, EMAIL_PW)
		server.send_message(msg)
		server.quit()
		return 0
	except:
		return 1

# 解答csvファイルとソースコードのアップロードと正答率計算
# curl -X POST -F 'json={"id": 1, "csv": "test_10.csv", "code": "app.py"}' -F 'csv=@/home/ishiguro/database/AI-STEP/dummy/test_10.csv' -F 'code=@/home/ishiguro/AI-STEP_Competition/BE/app.py' http://127.0.0.1:8001/upload
@app.route("/upload", methods=["POST"])
def upload():
	if request.method == "POST":
		# from から JSON 取得
		request_json_str = request.form.get("json")
		if request_json_str is None:
			return error_response(400, "リクエストにJSONがありません。")
		try:
			request_json = json.loads(request_json_str)
		except json.decoder.JSONDecodeError:
			return error_response(400, "渡されたJSON文字列をJSONに変換できません。")
		
		# JSON から id 取得
		if request_json.get("id") is None:
			return error_response(400, "ログインからやり直してください。")
		try:
			id = int(request_json.get("id")) # DB の id
		except ValueError:
			return error_response(400, "ログインからやり直してください。")

		# JSON から csv, code のファイル名取得
		if request_json.get("csv") is None or request_json.get("code") is None:
			return error_response(400, "ファイル名がありません。")
		csv_name = request_json.get("csv")
		code_name = request_json.get("code")

		# 解答csvファイルとソースコードファイルがあるか調べる. 
		if "csv" not in request.files:
			return error_response(400, "解答csvファイルを提出してください。")
		if "code" not in request.files:
			return error_response(400, "ソースコードファイルを提出してください。")

		name = None # ニックネーム

		# 更新対象の DB のデータ選択
		db_user = session.query(db).filter(db.id == id).one_or_none()
		if db_user is not None:
			name = db_user.name
		else:
			session.close()
			return error_response(400, "ログインからやり直してください。")
		
		# 提出回数の確認
		try:
			if upload_num_dict[name] >= MAX_UPLOAD_NUM:
				session.close()
				return error_response(400, "今日はこれ以上提出できません。")
		except:
			upload_num_dict[name] = 0

		# 解答csvファイルの一時保存
		csv_data = request.files["csv"] # 解答csvファイルのデータ
		tmp_csv = os.path.join(ANS_DIR, name, "tmp.csv")
		csv_data.save(tmp_csv)

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
		except IndexError:
			session.close()
			os.remove(tmp_csv)
			return error_response(500)
		err_str = err.decode("utf-8")
		if(err_str != ""):
			session.close()
			os.remove(tmp_csv)
			if "行目の列数が2以外です。" in err_str or "全データのフォーマットが誤りです。" in err_str:
				return error_response(400, err_str)
			return error_response(500, "エラーが発生しました。再提出してください。")
		try:
			ans_json = json.loads(res)
		except:
			session.close()
			os.remove(tmp_csv)
			return error_response(500, "エラーが発生しました。再提出してください。")
		ans = ans_json.get("ans")
		if(ans == ""):
			session.close()
			os.remove(tmp_csv)
			return error_response(500)

		# ディレクトリが消えていたら再生成
		if not os.path.isdir(os.path.join(ANS_DIR, name)):
			os.mkdir(os.path.join(ANS_DIR, name))
		else:
			# 過去に提出している場合は保存してある前回の解答csvファイルとソースコードを削除
			if os.path.isfile(db_user.csv):
				os.remove(db_user.csv)
			if os.path.isfile(db_user.code):
				os.remove(db_user.code)

		# 解答csvファイル保存
		csv = os.path.join(ANS_DIR, name, csv_name) # 解答csvファイルのパス
		copy2(tmp_csv, csv)
		os.remove(tmp_csv)

		# ソースコード保存
		code_data = request.files["code"] # ソースコードのデータ
		code = os.path.join(ANS_DIR, name, code_name) # ソースコードのパス
		code_data.save(code)

		# DB の情報更新
		db_user.ans = ans
		db_user.csv = csv
		db_user.code = code
		db_user.upload = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
		session.commit()

		# 登録した情報からレスポンス作成
		result_db = session.query(db).filter(db.name == name).one_or_none()
		session.close()
		if result_db is None:
			return error_response(500, "登録に失敗しました。再提出してください。")
		
		# 控えメールの送信
		mail_res = send_mail(result_db.name, result_db.mail, result_db.csv, result_db.code)

		upload_num_dict[result_db.name] += 1
		return make_response(jsonify({"id": result_db.id, "ans": result_db.ans, "correct": ans_json.get("correct"), "fail": ans_json.get("fail"), "num": upload_num_dict[result_db.name], "mail": mail_res, "message": ans_json.get("message")})), 200
	else:
		return error_response(400)