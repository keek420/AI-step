# 標準ライブラリ
from sys import argv
from concurrent.futures import ThreadPoolExecutor
from time import sleep

# 外部ライブラリ
from flask import *
from flask_cors import CORS
import schedule

# プロジェクト内ファイル
from api import get, login, settings, upload

# 設定
app = Flask(__name__)
CORS(app)
app.config["JSON_AS_ASCII"] = False
app.register_blueprint(get.app)
app.register_blueprint(login.app)
app.register_blueprint(upload.app)

# curl http://127.0.0.1:8001
@app.route("/")
def hello():
	return "hello AI-STEP", 200

@app.after_request
def after_request(response):
	response.headers.add('Access-Control-Allow-Origin', '*')
	response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
	response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS')
	return response

def schedule_run():
	while True:
		schedule.run_pending()
		sleep(1)


def main():
	if argv[-1] == "r":
		upload.init_upload_num()
	schedule.every().day.at("00:00").do(upload.clear_upload_num)
	tpe = ThreadPoolExecutor(max_workers=1)
	tpe.submit(schedule_run)
	app.run(host=settings.APP_HOST, port=settings.APP_PORT, debug=True,  use_debugger=False, use_reloader=False)
	tpe.shutdown()
	print("BE server is closed!")


if __name__ == "__main__":
	main()
