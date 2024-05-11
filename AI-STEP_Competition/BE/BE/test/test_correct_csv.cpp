#include <iostream>
#include <unordered_map>
#include <string>
#include <fstream>
#include <sstream>
#include <cmath>

int main(int argc, char* argv[]){
	if (argc < 3){
		std::cerr << "Usage: ./cal <Correct csv> <Class num>" << std::endl;
		return -1;
	}

	std::string c_path = argv[1]; // 正解csvファイルへのパス
	std::string c_buf; // 正解csvファイルのデータバッファ
	std::unordered_map<std::string, int> c_map;
	int class_num = 0;

	std::istringstream cnum_iss(argv[2]);
	cnum_iss >> class_num;
	//std::cout << class_num << std::endl;
	if (class_num == 0){
		std::cerr << "Usage: ./cal <Correct csv> <Class num>" << std::endl;
		return -1;
	}
	

	// 正解csvファイルの読み込み
	std::ifstream c_stream(c_path);
	std::string error_str = "";
	int row = 0;
	std::cout << "\"key\", \"value_str\", value, index" << std::endl;
	while (getline(c_stream, c_buf))
	{
		row++;
		int c_index = c_buf.find(",");
		if (c_index == std::string::npos){
			error_str += "Row" + std::to_string(row) + "\t" + "";
		}
		std::string key = c_buf.substr(0, c_buf.find(","));
		std::string value_str = c_buf.substr(c_buf.find(",") + 1);
		std::istringstream iss(value_str);
		int value;
		iss >> value;
		std::cout << "\"" << key << "\", \"" << value_str << "\", " << value << ", " << c_buf.find(",") << std::endl;
		if (value < 1 && value > class_num)
		/*if (c_map.find(key) == c_map.end()){
			std::istringstream iss(c_buf.substr(c_buf.find(",") + 1));
			iss >> c_map[key];
		}*/
	}
	/*if (c_map.empty()){
		std::cerr << c_path << " is not exists." << std::endl;
		return -1;
	}*/

	return 0;
}