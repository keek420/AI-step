# 標準ライブラリ
#from dateutil.tz import gettz

# 外部ライブラリ
from flask import Blueprint, jsonify
from flask.globals import request
from flask.helpers import make_response

# プロジェクト内のファイル
from .common import error_response
from .db import *

# 設定
app = Blueprint("get", __name__)

# 提出者の一覧を取得
# curl http://127.0.0.1:8001/get
@app.route("/get", methods=["GET"])
def get_list():
	id = 0 # パラメータ変数

	# DB の id をパラメータから取得
	if request.args.get("id") is not None:
		try:
			id = int(request.args.get("id"))
		except ValueError:
			return error_response(400, "ログインからやり直してください。")
		if id <= 0:
			return error_response(400, "ログインからやり直してください。")

	if request.method == "GET":
		# データベースから全データ取得
		all_db = session.query(db).all()
		session.close()

		# 正答率順でソート
		all_db.sort(key=lambda x: float(x.ans), reverse=True)

		# response 作成
		response_dict = {}
		response_dict["List"] = []
		rank = 0
		for i, data in enumerate(all_db):
			if (i == 0) or (all_db[i - 1].ans != data.ans):
				rank = i + 1

			if ((id == data.id) and (id != 0)) or (id == 0):
				response_dict["List"].append({})
				response_dict["List"][-1]["rank"] = rank
				response_dict["List"][-1]["name"] = data.nickname
				response_dict["List"][-1]["ans"] = data.ans
				response_dict["List"][-1]["is_error"] = data.is_error
				response_dict["List"][-1]["error_msg"] = data.error_msg

				print(data.ans)

				print(data.csv)
				if data.upload_date is None:
					#response_dict["List"][-1]["time"] = data.upload
					response_dict["List"][-1]["time"] = data.upload_date
				else:
					#response_dict["List"][-1]["time"] = data.upload.strftime("%Y-%m-%d %H:%M:%S")
					response_dict["List"][-1]["time"] =  data.upload_date
		response = make_response(jsonify(response_dict))
		print(response)
		return response, 200
	else:
		return error_response(400)