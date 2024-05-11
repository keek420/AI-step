import 'package:http/http.dart' as http;

import 'dart:convert';

import 'setting.dart';

class RankData{
  int id = 0;
  String name = "";
  String ans = "";
  int rank = 0;
  String time = "";
  bool is_error = true;
  String error_msg = "";

  RankData();

  RankData.fromJson(Map<String, dynamic> json){
    if(json["id"] != null) id = json["id"];
    name = json["name"];
    if(json["ans"] != null) ans = json["ans"];
    if(json["rank"] != null) rank = json["rank"];
    if(json["time"] != null) time = json["time"];
    if(json["is_error"] != null) is_error = json["is_error"];
    if(json["error_msg"] != null) error_msg = json["error_msg"];
  }

  showData(){
    print("id: $id, name: $name, ans: $ans, rank: $rank, time: $time is_error: $is_error, error_msg: $error_msg");
  }

  clear(){
    id = 0;
    name = "";
    ans = "";
    rank = 0;
    time = "";
    is_error = true;
    error_msg = "";
  }

  Future<String?> getRankData() async{
    if(id <= 0) return null;
    /*Uri url = Uri.http(
      serverUrl,
      phpPath,
      {"route": "get", "id": id.toString()}
    );*/
    //Uri url = Uri.https(serverUrl, phpPath, {"route": "get", "id": id.toString()});
    Uri url = Uri.http(serverUrl, phpPath, {"route": "get", "id": id.toString()});
    //url = Uri.http("localhost:8001", "/get", {"route": "get", "id": id.toString()});

    http.Response response = await http.get(url);

    String responseBody;
    Map<String, dynamic> jsonResponse;
    try{
      responseBody = utf8.decode(response.bodyBytes);
      jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;
      if(response.statusCode != 200){
        return "Error[${response.statusCode}]: ${jsonResponse["message"]}";
      }
    }
    catch (e){
      return "Error[${response.statusCode}]: 通信に失敗しました。";
    }

    if(jsonResponse["List"] != null){
      name = jsonResponse["List"][0]["name"];
      ans = jsonResponse["List"][0]["ans"];
      rank = jsonResponse["List"][0]["rank"];
      is_error  = jsonResponse["List"][0]["is_error"];
      error_msg = jsonResponse["List"][0]["error_msg"];
      if(jsonResponse["List"][0]["time"] != null) time = jsonResponse["List"][0]["time"];
    }
    return null;
  }
}

class RankDataList{
  List<RankData> rankDataList = [];
  String errorStr = "";

  RankDataList();

  Future<void> getRankDataList() async{
    /*Uri url = Uri.http(
      serverUrl,
      phpPath,
      {"route": "get"}
    );*/
    //Uri url = Uri.https(serverUrl, phpPath, {"route": "get"});
    Uri url = Uri.http(serverUrl, phpPath, {"route": "get"});
    //url = Uri.http("localhost:8001", "/get", {"route": "get"});
    print("aaaaaa");
    http.Response response = await http.get(url);
    String responseBody;

    print(url);
    print(response);
    Map<String, dynamic> jsonResponse;
    try{
      responseBody = utf8.decode(response.bodyBytes);

      print("jsonRespons\n");
      print(responseBody);
      jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;
      if(response.statusCode != 200){

        errorStr = "Error[${response.statusCode}]: ${jsonResponse["message"]}";
        return;
      }
    }
    catch (e){
      errorStr = "Error[${response.statusCode}]: 通信に失敗しました。";
      return;
    }
    print("LIST\n");
    print(jsonResponse["List"]);

    if(jsonResponse["List"] != null){
      rankDataList.clear();
      jsonResponse["List"].forEach((json){
        rankDataList.add(RankData.fromJson(json));
      });
    }

    for (var element in rankDataList) {element.showData();}
  }
}