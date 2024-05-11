import os
from datetime import datetime

from api import db

def main():
	all_db = db.session.query(db.db).all()
	if all_db is None:
		print("Data is empty in DB.")
		db.session.close()
		exit(1)

	for one_db in all_db:
		time = None
		if os.path.isfile(one_db.csv):
			time = os.path.getmtime(one_db.csv)
		elif os.path.isfile(one_db.code):
			time = os.path.getmtime(one_db)
		if time is not None:
			one_db.upload = datetime.fromtimestamp(time).strftime("%Y-%m-%d %H:%M:%S")

	db.session.commit()
	result_db = db.session.query(db.db).all()
	db.session.close()
	for r in result_db:
		print(f"{r.name}: {r.upload}")

if __name__ == "__main__":
	main()