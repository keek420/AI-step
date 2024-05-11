import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

import 'communicate.dart';
import 'setting.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({Key? key, required this.myData}) : super(key: key);
  final RankData myData;

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  PlatformFile? _csvFile;
  PlatformFile? _codeFile;
  Text _message = const Text("");
  bool _isLoading = false;
  Widget? _resultWidget;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text("AI-STEP コンペティション"),
            titleTextStyle: const TextStyle(color: Colors.white, fontSize: 32),
            backgroundColor: Colors.black,
          ),
          body: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Container(
              margin: const EdgeInsets.all(10.0),
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Visibility(
                      visible: widget.myData.id <= 0,
                      child: Column(
                        children: [
                          Visibility(
                              visible: _message.data != "",
                              child: _message
                          ),
                          const Text("提出機能はログイン済みユーザー限定の機能となっております。"),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                child: const Text("こちら"),
                                onPressed: () async{
                                  RankData? result = await Navigator.of(context).pushNamed("/login") as RankData?;
                                  if (result is RankData){
                                    widget.myData.id = result.id;
                                    widget.myData.name = result.name;
                                    await widget.myData.getRankData();
                                    _message = const Text("");
                                    setState(() {});
                                  }
                                },
                              ),
                              const Text("からログインしてください。")
                            ],
                          )
                        ],
                      ),
                    ),
                    Visibility(
                      visible: widget.myData.id > 0 && _resultWidget == null,
                      child: Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.black12, width: 1),
                            borderRadius: const BorderRadius.all(Radius.circular(5.0))
                        ),
                        padding: const EdgeInsets.all(5.0),
                        margin: const EdgeInsets.all(10.0),
                        width: 800,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "解答の提出",
                                style: TextStyle(fontSize: 24),
                              ),
                              Text("1日に$maxUploadNum回まで提出できます"),
                              Visibility(
                                  visible: _message.data != "",
                                  child: _message
                              ),
                              const SizedBox(height: 10.0,),
                              Row(
                                children: [
                                  const Text("ニックネーム: "),
                                  Text(widget.myData.name),
                                ],
                              ),
                              const SizedBox(height: 5.0,),
                              Row(
                                children: [
                                  const Text("解答ファイル(.csv): "),
                                  if(_csvFile != null)
                                    Text(_csvFile!.name),
                                  const SizedBox(width: 5,),
                                  ElevatedButton(
                                    child: _csvFile == null? const Text("選択"): const Text("再選択"),
                                    onPressed: () async{
                                      await pickedCsv();
                                      setState((){});
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5.0,),
                              Row(
                                children: [
                                  const Text("ソースコード: "),
                                  if(_codeFile != null)
                                    Text(_codeFile!.name),
                                  const SizedBox(width: 5,),
                                  ElevatedButton(
                                    child: _codeFile == null? const Text("選択"): const Text("再選択"),
                                    onPressed: () async{
                                      await pickedCode();
                                      setState((){});
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10.0,),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  InkWell(
                                    onTap: (){
                                      if(Navigator.of(context).canPop()){
                                        Navigator.of(context).pop(widget.myData);
                                      }
                                    },
                                    child: const Text("キャンセル"),
                                  ),
                                  const SizedBox(width: 10,),
                                  _csvFile != null && _codeFile != null?
                                  ElevatedButton(
                                    onPressed: () async{
                                      if(_csvFile == null || _codeFile == null) return;
                                      int? result = await showDialog<int>(
                                          context: context,
                                          builder: (BuildContext context){
                                            return AlertDialog(
                                              title: const Text("最終確認"),
                                              content: SizedBox(
                                                height: 200,
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text("以下のファイルを提出しますが、よろしいですか?"),
                                                    const Text("※前回の結果は破棄されます。", style: TextStyle(color: Colors.red),),
                                                    const SizedBox(height: 5,),
                                                    Text("ニックネーム: ${widget.myData.name}"),
                                                    Text("解答ファイル(.csv): ${_csvFile!.name}"),
                                                    Text("ソースコード: ${_codeFile!.name}"),
                                                  ],
                                                ),
                                              ),
                                              actions: <Widget>[
                                                TextButton(
                                                  child: const Text("Cancel"),
                                                  onPressed: () {
                                                    Navigator.of(context).pop(0);
                                                  },
                                                ),
                                                TextButton(
                                                  child: const Text("OK"),
                                                  onPressed: () {
                                                    Navigator.of(context).pop(1);
                                                  },
                                                ),
                                              ],
                                            );
                                          }
                                      );
                                      if(result == 1){
                                        await uploadData();
                                        setState(() {});
                                      }
                                    },
                                    child: const Text("提出"),
                                  ):
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.blue[100],
                                    ),
                                    onPressed: (){},
                                    child: const Text("提出"),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    if(_resultWidget != null)
                      _resultWidget!,
                  ],
                ),
              ),
            ),
          ),
        ),
        if(_isLoading)
          const Opacity(
            opacity: 0.7,
            child: ModalBarrier(
              dismissible: false,
              color: Colors.black,
            ),
          ),
        if(_isLoading) const Center(child: CircularProgressIndicator())
      ],
    );
  }

  Future<void> pickedCsv() async{
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withReadStream: true,
        type: FileType.custom,
        allowedExtensions: ["csv"]
    );
    if (result == null){
      return;
    }
    _csvFile = result.files.single;
  }

  Future<void> pickedCode() async{
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withReadStream: true,
        type: FileType.any,
    );
    if (result == null){
      return;
    }
    _codeFile = result.files.single;
  }

  Future<int> uploadData() async{
    if(widget.myData.id <= 0){
      _message = const Text(
        "ログインからやり直してください。",
        style: TextStyle(color: Colors.red),
      );
      return 0;
    }
    else if(_csvFile == null || _codeFile == null){
      _message = const Text(
        "提出ファイルが足りていません。",
        style: TextStyle(color: Colors.red),
      );
      return 0;
    }
    else if(_csvFile!.size > maxSize || _codeFile!.size > maxSize){
      _message = const Text(
        "提出ファイルが大きすぎます。",
        style: TextStyle(color: Colors.red),
      );
      return 0;
    }

    setState(() {
      _isLoading = true;
    });

    String csvName = _csvFile!.name;
    String codeName = _codeFile!.name;

    //Uri url = Uri.http(serverUrl, "upload");
    //Uri url = Uri.http(serverUrl, phpPath);
    Uri url = Uri.https(serverUrl, phpPath);
    http.MultipartRequest request = http.MultipartRequest("POST", url);
    Map<String, String> map = {
      "id": widget.myData.id.toString(),
      "csv": csvName,
      "code": codeName
    };
    request.fields["json"] = json.encode(map);
    request.fields["route"] = "upload";

    request.files.add(
      http.MultipartFile(
        "csv",
        _csvFile!.readStream!,
        _csvFile!.size,
        filename: _csvFile!.name
      ),
    );

    request.files.add(
      http.MultipartFile(
          "code",
          _codeFile!.readStream!,
          _codeFile!.size,
          filename: _codeFile!.name
      ),
    );

    http.StreamedResponse response = await request.send();

    String result = await response.stream.bytesToString();
    Map<String, dynamic> jsonResponse = jsonDecode(result) as Map<String, dynamic>;

    setState(() {
      _isLoading = false;
      _csvFile = null;
      _codeFile = null;
    });

    if(response.statusCode != 200){
      _message = Text(
        " ${jsonResponse["message"]} (${response.statusCode})",
        style: const TextStyle(color: Colors.red,),
      );
      return 0;
    }
    widget.myData.id = jsonResponse["id"];

    _resultWidget = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "解答を受領しました",
            style: TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 10.0,),
          Row(
            children: [
              const Text("ニックネーム: "),
              Text(widget.myData.name),
            ],
          ),
          const SizedBox(height: 5.0,),
          Text("解答ファイル(.csv): $csvName"),
          const SizedBox(height: 5.0,),
          Text("ソースコード: $codeName"),
          const SizedBox(height: 5.0,),
          Text("正答率(%): ${jsonResponse["ans"].toString()}"),
          const SizedBox(height: 5.0,),
          Text("有効データ数: ${jsonResponse["correct"].toString()}"),
          const SizedBox(height: 5.0,),
          Text("無効データ数: ${jsonResponse["fail"].toString()}"),
          const SizedBox(height: 5.0,),
          Text("本日の提出回数: ${jsonResponse["num"].toString()}"),
          const SizedBox(height: 5.0,),
          Text("控えメールの送信: ${jsonResponse["mail"]==0?"成功":"失敗"}"),
          Visibility(
            visible: jsonResponse["message"] != "",
            child: Column(
              children: [
                const SizedBox(height: 5.0,),
                Text(jsonResponse["message"])
              ],
            ),
          ),
          const SizedBox(height: 10.0,),
          ElevatedButton(
            onPressed: () {
              if(Navigator.of(context).canPop()){
                Navigator.of(context).pop(widget.myData);
              }
              else{
                Navigator.of(context).pushReplacementNamed("/home", arguments: widget.myData);
              }
            },
            child: const Text("ホーム画面に戻る"),
          ),
        ],
      ),
    );
    return 1;
  }
}