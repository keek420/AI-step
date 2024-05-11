import smtplib
from email.mime.text import MIMEText
from datetime import datetime

# 控えメールの送信
def send_mail(name:str, mail:str, csv:str, code:str, ):
	from_email = "ai-step_competition@outlook.com"
	to_email = mail
	mail_title = f"解答の受領のお知らせ"
	message = f"""
	{name} 様\n
	以下の内容で解答を受領しました。\n
	正答率や現在の順位は以下からご確認ください。\n
	https://ai-step.ec.t.kanazawa-u.ac.jp/competition_01\n
	解答提出日時: {datetime.now().strftime("%Y年%m月%d日 %H:%M:%S")}\n
	解答ファイル: {csv}\n
	ソースコードファイル: {code}\n
	"""

	msg = MIMEText(message, "plain")
	msg["Subject"] = mail_title
	msg["To"] = to_email
	msg["From"] = from_email

	smtp_host = "smtp.office365.com"
	smtp_port = 587
	smtp_password = "AI-STEPmail"

	server = smtplib.SMTP(smtp_host, smtp_port)
	print("Finish server")
	print(server)
	server.ehlo()
	print("Finish first ehlo")
	server.starttls()
	print("Finish starttls")
	server.login(from_email, smtp_password)
	print("Finish login")
	server.send_message(msg)
	print("Finish send message")
	server.quit()
	print("Finish quit")

if __name__ == "__main__":
	send_mail("石黒", "kuuohur2960@stu.kanazawa-u.ac.jp", "test.csv", "test.code")