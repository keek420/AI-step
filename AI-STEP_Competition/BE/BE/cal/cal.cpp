#include <iostream>
#include <unordered_map>
#include <string>
#include <fstream>
#include <sstream>
#include <cmath>

#include "nlohmann/json.hpp"

std::string trim(const std::string& string){
	std::string result;
	const char* trimCharacterList = " \t\v\r\n";

	// 左側からトリムする文字以外が見つかる位置を検索します。
	std::string::size_type left = string.find_first_not_of(trimCharacterList);

	if (left != std::string::npos){
		// 左側からトリムする文字以外が見つかった場合は、同じように右側からも検索します。
		std::string::size_type right = string.find_last_not_of(trimCharacterList);

		// 戻り値を決定します。ここでは右側から検索しても、トリムする文字以外が必ず存在するので判定不要です。
		result = string.substr(left, right - left + 1);
	}
	return result;
}

int main(int argc, char* argv[]){
	if (argc < 4){
		std::cerr << "Usage: ./cal <Correct csv> <Test csv> <Class num>" << std::endl;
		return -1;
	}

	std::string c_path = argv[1]; // 正解csvファイルへのパス
	std::string t_path = argv[2]; // 解答csvファイルへのパス
	std::string c_buf; // 正解csvファイルのデータバッファ
	std::string t_buf; // 解答csvファイルのデータバッファ
	std::unordered_map<std::string, int> c_map; // 正解csvファイルの辞書
	std::unordered_map<std::string, int> t_map; // 解答csvファイルの辞書
	int class_num = 0; // クラス番号
	nlohmann::json result_json; // 結果JSON

	std::istringstream cnum_iss(argv[3]);
	cnum_iss >> class_num;
	//std::cout << class_num << std::endl;
	if (class_num == 0){
		std::cerr << "Usage: ./cal <Correct csv> <Test csv> <Class num>" << std::endl;
		return -1;
	}

	// 正解csvファイルの読み込み
	std::ifstream c_stream(c_path);
	while (getline(c_stream, c_buf))
	{
		std::string key = trim(c_buf.substr(0, c_buf.find(",")));
		if (c_map.find(key) == c_map.end()){
			std::istringstream iss(trim(c_buf.substr(c_buf.find(",") + 1)));
			iss >> c_map[key];
		}
	}
	if (c_map.empty()){
		std::cerr << c_path << " is not exists." << std::endl;
		return -1;
	}

	// 解答csvファイル読み込み
	std::ifstream t_stream(t_path);
	unsigned long row = 0;
	unsigned long correct_data_num = 0;
	unsigned long fail_data_num = 0;
	std::stringstream error_ss;
	while (getline(t_stream, t_buf))
	{
		row++;
		int index = t_buf.find(",");
		//std::cout << t_buf << std::endl;
		//
		//std::cout << index << std::endl;
		//// 列数が2か確認
		if(index == std::string::npos || t_buf.find_last_of(",") != index){
			std::cerr << row << "行目の列数が2以外です。";
			return -1;
		}
		std::string key = trim(t_buf.substr(0, index));
		std::string value_str = trim(t_buf.substr(index + 1));
		int value = 0;
		std::istringstream iss(value_str);
		iss >> value;
		// c_map.find(key) == c_map.end(): 正解csvファイルでファイル名が未定義
		// value < 1 || value > class_num: クラス番号が0以上 class_num 以下ではない
		// std::to_string(value) != value_str: 余分なデータがクラス番号についている
		// t_map.find(key) != t_map.end(): ファイル名が重複
		if(c_map.find(key) == c_map.end() || value < 0 || value > class_num || std::to_string(value) != value_str || t_map.find(key) != t_map.end()){
			fail_data_num++;
			error_ss << row << ", ";
			continue;
		}
		else{
			correct_data_num++;
			t_map[key] = value;
		}
	}
	if (t_map.empty()){
		std::cerr << "全データのフォーマットが誤りです。" << std::endl;
		return -1;
	}

	// 正答率計算
	unsigned long all_num = 0;
	unsigned long correct_num = 0;
	double ans = 0;
	char ans_str[10];
	for (auto c_it = c_map.begin(); c_it != c_map.end(); c_it++, all_num++){
		if (t_map.find(c_it->first) != t_map.end()){
			if (t_map.at(c_it->first) == c_it->second){
				correct_num++;
			}
		}
	}
	ans = std::floor((double)correct_num/(double)all_num*100000)/1000;
	//std::cout << all_num << "\t" << correct_num << "\t" << ans << std::endl;
	sprintf(ans_str, "%.3f", ans);

	// 結果をJSON形式に保存
	std::string error_str = error_ss.str();
	if (error_str != "") error_str = "以下の行は無効データでした。\n" + error_str.substr(0, error_str.length() - 2);
	result_json["ans"] = ans_str;
	result_json["correct"] = correct_data_num;
	result_json["fail"] = fail_data_num;
	result_json["message"] = error_str;
	std::cout << result_json << std::flush;

	return 0;
}
