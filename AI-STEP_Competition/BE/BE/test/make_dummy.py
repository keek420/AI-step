import csv
import sys
from random import randint


DUMMY_DIR = "/mnt/c/Users/Thasegawa/Documents/SAT3-01/hasegawa/work/AI-STEP/AI-STEP_Competition_test/AI-STEP_Competition/BE/autocheck/dummy_data"

def main():
	if len(sys.argv) < 2:
		print(f"Usage: make_dummy.py <Data Num>", file=sys.stderr)
		exit(1)
	data_num = 0
	try:
		data_num = int(sys.argv[1])
		if data_num > 1000000:
			print(f"Usage: make_dummy.py <Data Num>", file=sys.stderr)
			exit(1)
	except ValueError:
		print(f"Usage: make_dummy.py <Data Num>", file=sys.stderr)
		exit(1)
	dummy_path = DUMMY_DIR + f"dummy_{data_num}.csv"
	with open(dummy_path, "w") as f:
		writer = csv.writer(f)
		for i in range(data_num):
			writer.writerow([f"IMG_{i:06}.jpg", randint(1, 5)])

if __name__ == "__main__":
	main()
