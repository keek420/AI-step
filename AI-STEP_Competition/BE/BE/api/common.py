# 標準ライブラリ

# 外部ライブラリ
from flask import jsonify
from flask.helpers import make_response

# エラーメッセージ返還
def error_response(status_code, message=None):
	MESSAGES = {400: "不正なリクエストです。",
				404: "リソースが見つかりません。",
				500: "エラーが発生しました。"}
	error_response = {}
	if message is None:
		error_response["message"] = MESSAGES[status_code]
	else:
		error_response["message"] = message
	return make_response(jsonify(error_response)), status_code
