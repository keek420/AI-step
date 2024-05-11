# 標準ライブラリ
import json
import os
from random import randint

# 外部ライブラリ
from flask import Blueprint, jsonify
from flask.globals import request
from flask.helpers import make_response

# プロジェクト内のファイル
from .common import error_response
from .db import *
from .settings import ANS_DIR, upload_num_dict

# 設定
app = Blueprint("login", __name__)

# ログイン
def login(name:str|None, mail:str|None, pw:str|None):
	if (name is None) and (mail is None):
		return -1
	if pw is None:
		session.close()
		return -2
	all_db = session.query(db)
	if name is not None:
		all_db = all_db.filter(db.name == name)
		if all_db.one_or_none() is None:
			session.close()
			return -3
	if mail is not None:
		all_db = all_db.filter(db.mail == mail)
		if all_db.one_or_none() is None:
			session.close()
			return -4
	one_db = all_db.one()
	session.close()
	if pw != one_db.pw:
		if name is not None:
			return -3
		elif mail is not None:
			return -4
		return -1
	return one_db.id

# ログイン処理
# curl 'http://127.0.0.1:8001/login?name=TESTNAME1&pw=TEST1'
@app.route("/login", methods=["GET"])
def try_login():
	# パラメータ変数
	parameters = {
		"name": None,
		"pw": None,
		"mail": None
	}

	if request.args.get("name") is not None:
		parameters["name"] = request.args.get("name")
	if request.args.get("pw") is not None:
		parameters["pw"] = request.args.get("pw")
	if request.args.get("mail") is not None:
		parameters["mail"] = request.args.get("mail")

	if request.method == "GET":
		result = 0
		# ログインの結果からエラー返還
		result = login(name=parameters["name"], mail=parameters["mail"], pw=parameters["pw"])
		if result == -1:
			return error_response(400, "ニックネームかメールアドレスを設定してください。")
		elif result == -2:
			return error_response(400, "パスワードを設定してください。")
		elif result == -3:
			return error_response(400, "ニックネームかパスワードが間違っています。")
		elif result == -4:
			return error_response(400, "メールアドレスかパスワードが間違っています。")
		elif parameters["name"] is None:
			parameters["name"] = session.query(db).filter(db.id == result).one().name
			session.close()
		
		return make_response(jsonify({"id": result, "name": parameters["name"]})), 200
	else:
		return error_response(400)

# 新規登録
# curl -X POST -F 'json={"name": "TEST1", "pw": "TEST1", "mail": "TEST1@test.com"}' http://127.0.0.1:8001/register
@app.route("/register", methods=["POST"])
def register():
	# パラメータ変数
	parameters = {
		"name": None,
		"pw": None,
		"mail": None
	}

	if request.method == "POST":
		# JSON 取得
		request_json_str = request.form.get("json")
		if request_json_str is None:
			return error_response(400, "リクエストにJSONがありません。")
		try:
			request_json = json.loads(request_json_str)
		except json.decoder.JSONDecodeError:
			return error_response(400, "渡されたJSON文字列をJSONに変換できません。")

		# 変数格納
		parameters["name"] = request_json.get("name")
		parameters["pw"] = request_json.get("pw")
		parameters["mail"] = request_json.get("mail")

		# pw, mail のどちらかがなければエラー処理
		error_str = ""
		for key, value in parameters.items():
			if (value is None) and (key != "name"):
				error_str += f"{key} を渡してください。\n"
		if error_str != "":
			return error_response(400, error_str)
		
		# name が DB にもディレクトリにも登録されていないことの確認
		all_db = session.query(db)
		error_str = ""
		if parameters["name"] is None: # name が渡されていない場合は「名無しさん_{ランダム5桁数値}」とする
			while True:
				tmp_name = f"名無しさん_{randint(0, 99999):05d}"
				tmp_fdb = all_db.filter(db.name == tmp_name).one_or_none()
				# tmp_list が空 = DB 上に tmp_name がないため name を確定させる
				if (tmp_fdb is None) and (not os.path.isdir(os.path.join(ANS_DIR, tmp_name))):
					parameters["name"] = tmp_name
					break
		else:
			fname_db = all_db.filter(db.name == parameters["name"]).one_or_none()
			if (fname_db is not None) or (os.path.isdir(os.path.join(ANS_DIR, parameters["name"]))):
				error_str += "既にそのニックネームは使われています。\n"

		# mail が DB に登録されていないことの確認
		fmail_db = all_db.filter(db.mail == parameters["mail"]).one_or_none()
		if fmail_db is not None:
			error_str += "既にそのメールアドレスは使われています。"
		if error_str != "":
			session.close()
			return error_response(400, error_str)

		# 提出ファイル保存用ディレクトリ作成
		if not os.path.isdir(os.path.join(ANS_DIR, parameters["name"])):
			os.mkdir(os.path.join(ANS_DIR, parameters["name"]))

		# DB への登録
		new_db = db()
		new_db.name = parameters["name"]
		new_db.pw = parameters["pw"]
		new_db.mail = parameters["mail"]
		new_db.ans = "0.000"
		new_db.csv = os.path.join(ANS_DIR, parameters["name"])
		new_db.code = os.path.join(ANS_DIR, parameters["name"])
		session.add(new_db)
		session.commit()

		# 登録されていることの確認
		result = login(name=parameters["name"], mail=parameters["mail"], pw=parameters["pw"])
		if result <= 0:
			return error_response(500, "内部処理でエラーが発生しました。")

		upload_num_dict[parameters["name"]] = 0
		return make_response(jsonify({"id": result, "name": parameters["name"]})), 200
	else:
		return error_response(400)