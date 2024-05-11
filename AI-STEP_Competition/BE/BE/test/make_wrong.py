import csv
import sys
from random import shuffle
from decimal import ROUND_DOWN, Decimal
from os import path

CLASS_NUM = 4

def main():
	if len(sys.argv) < 3:
		print(f"Usage: make_wrong.py <Original data> <Correct percentage>", file=sys.stderr)
		exit(1)
	ori_data = sys.argv[1]
	data = []
	try:
		ans = float(sys.argv[2])
		if ans >= 100:
			print(f"Usage: make_wrong.py <Original data> <Correct percentage>", file=sys.stderr)
			exit(1)
	except ValueError:
		print(f"Usage: make_wrong.py <Original data> <Correct percentage>", file=sys.stderr)
		exit(1)
	with open(ori_data, "r") as rf:
		reader = csv.reader(rf)
		for row in reader:
			data.append([])
			data[-1].append(row[0])
			try:
				data[-1].append(int(row[1]))
			except ValueError:
				print(f"{ori_data} is wrong!", file=sys.stderr)
				exit(1)

	data_len = len(data)
	correct_num = data_len
	now_percent = float(Decimal(f"{100*(correct_num/data_len):.4f}").quantize(Decimal("0.001"), rounding=ROUND_DOWN))
	random_list = list(range(data_len))
	shuffle(random_list)
	for num in random_list:
		if now_percent <= ans:
			break
		data[num][1] = data[num][1]%CLASS_NUM + 1
		correct_num -= 1
		now_percent = now_percent = float(Decimal(f"{100*(correct_num/data_len):.4f}").quantize(Decimal("0.001"), rounding=ROUND_DOWN))

	ans_str = f"{correct_num/data_len*100:.4f}".replace(".", "-")
	wrong_path = path.join(path.dirname(ori_data), f"wrong_{data_len}_{ans_str}.csv")
	with open(wrong_path, "w") as wf:
		writer = csv.writer(wf)
		for d in data:
			writer.writerow(d)

if __name__ == "__main__":
	main()