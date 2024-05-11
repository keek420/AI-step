import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

import 'dart:convert';

import 'communicate.dart';
import 'setting.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key, required this.myData}) : super(key: key);
  final RankData myData;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  int _statusCode = 200;
  final _nameController = TextEditingController();
  final _mailController = TextEditingController();
  final _pwController = TextEditingController();
  final _rePwController = TextEditingController();
  bool _obscure = true;
  Text _message = const Text("");
  String _sendName = "";
  String _sendMail = "";
  bool _isLoading = false;
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _mailFocusNode = FocusNode();
  final FocusNode _pwFocusNode = FocusNode();
  final FocusNode _rePwFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if(!Navigator.of(context).canPop()){
      Future.delayed(const Duration(seconds: 3), () {
        Navigator.of(context).pushReplacementNamed("/home");
      });
    }
  }

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
                child: Navigator.of(context).canPop()?
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.black12, width: 1),
                          borderRadius: const BorderRadius.all(Radius.circular(5.0))
                      ),
                      padding: const EdgeInsets.all(5.0),
                      margin: const EdgeInsets.all(10.0),
                      width: 310,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "アカウントの作成",
                            style: TextStyle(fontSize: 24),
                          ),
                          Visibility(
                              visible: _message.data != "",
                              child: _message
                          ),
                          const SizedBox(height: 10.0,),
                          const Text("ニックネーム"),
                          Focus(
                            child: SizedBox(
                              width: 300,
                              child: TextFormField(
                                decoration: const InputDecoration(
                                    hintText: "無記入だと自動生成",
                                    border: OutlineInputBorder()
                                ),
                                controller: _nameController,
                                focusNode: _nameFocusNode,
                              ),
                            ),
                            onFocusChange: (hasFocus){
                              if(!hasFocus) {
                                setState(() {});
                              } else {
                                _nameFocusNode.requestFocus();
                              }
                            },
                          ),
                          Visibility(
                            visible: (_statusCode == 401 || _statusCode == 403)&&(_nameController.text == _sendName),
                            child: const Text("! このニックネームは既に使用されています。", style: TextStyle(color: Colors.red, fontSize: 12),),
                          ),
                          Visibility(
                            visible: !RegExp(r"^([^\x01-\x7E]|\w)+$").hasMatch(_nameController.text) && _nameController.text != "",
                            child: const Text("! ニックネームでは半角英数字, 日本語, \"_\"以外は使用禁止です。", style: TextStyle(color: Colors.red, fontSize: 12),),
                          ),
                          const SizedBox(height: 5.0,),
                          const Row(
                            children: [
                              Text("メールアドレス"),
                              Text("*", style: TextStyle(color: Colors.red),),
                            ],
                          ),
                          Focus(
                            child: SizedBox(
                              width: 300,
                              child: TextFormField(
                                decoration: const InputDecoration(
                                    hintText: "メールアドレスを入力",
                                    border: OutlineInputBorder()
                                ),
                                controller: _mailController,
                                focusNode: _mailFocusNode,
                              ),
                            ),
                            onFocusChange: (hasFocus){
                              if(!hasFocus) {
                                setState(() {});
                              } else {
                                _mailFocusNode.requestFocus();
                              }
                            },
                          ),
                          Visibility(
                            visible: (_statusCode == 402)&&(_mailController.text == _sendMail),
                            child: const Text("! このメールアドレスは既に使用されています。", style: TextStyle(color: Colors.red, fontSize: 12),),
                          ),
                          Visibility(
                            visible: !RegExp(r".*@.*\..*").hasMatch(_mailController.text),
                            child: const Text("! メールアドレスが正しくありません。", style: TextStyle(color: Colors.red, fontSize: 12),),
                          ),
                          const SizedBox(height: 5.0,),
                          const Row(
                            children: [
                              Text("パスワード"),
                              Text("*", style: TextStyle(color: Colors.red),),
                            ],
                          ),
                          Focus(
                            child: SizedBox(
                              width: 300,
                              child: TextFormField(
                                decoration: InputDecoration(
                                  hintText: "半角英数字で最低6文字",
                                  border: const OutlineInputBorder(),
                                  suffixIcon: GestureDetector(
                                    onTap: (){
                                      setState(() {
                                        _obscure = !_obscure;
                                      });
                                    },
                                    child: Icon(
                                        _obscure? Icons.visibility: Icons.visibility_off
                                    ),
                                  ),
                                ),
                                controller: _pwController,
                                focusNode: _pwFocusNode,
                                obscureText: _obscure,
                                autocorrect: false,
                                enableInteractiveSelection: false,
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z0-9]"))],
                              ),
                            ),
                            onFocusChange: (hasFocus){
                              if(!hasFocus) {
                                setState(() {});
                              } else {
                                _pwFocusNode.requestFocus();
                              }
                            },
                          ),
                          Visibility(
                            visible: _pwController.text.length < 6,
                            child: const Text("! パスワードが短すぎます。", style: TextStyle(color: Colors.red, fontSize: 12),),
                          ),
                          const SizedBox(height: 5.0,),
                          const Row(
                            children: [
                              Text("パスワードの再入力"),
                              Text("*", style: TextStyle(color: Colors.red),),
                            ],
                          ),
                          Focus(
                            child: SizedBox(
                              width: 300,
                              child: TextFormField(
                                decoration: const InputDecoration(
                                    hintText: "同じパスワードを入力してください",
                                    border: OutlineInputBorder()
                                ),
                                controller: _rePwController,
                                focusNode: _rePwFocusNode,
                                obscureText: true,
                                autocorrect: false,
                                enableInteractiveSelection: false,
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z0-9]"))],
                              ),
                            ),
                            onFocusChange: (hasFocus){
                              if(!hasFocus) {
                                setState(() {});
                              } else {
                                _rePwFocusNode.requestFocus();
                              }
                            },
                          ),
                          Visibility(
                            visible: _pwController.text != _rePwController.text,
                            child: const Text("! パスワードが異なります。", style: TextStyle(color: Colors.red, fontSize: 12),),
                          ),
                          const SizedBox(height: 10.0,),
                          const Row(
                            children: [
                              Text("*", style: TextStyle(color: Colors.red, fontSize: 12),),
                              Text("が付いた項目は入力が必須です。", style: TextStyle(fontSize: 12),),
                            ],
                          ),
                          const SizedBox(height: 10.0,),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(fixedSize: const Size(300, 50)),
                            onPressed: () async{
                              if (!RegExp(r".*@.*\..*").hasMatch(_mailController.text) || _pwController.text.length < 6 || _pwController.text != _rePwController.text || (!RegExp(r"^([^\x01-\x7E]|\w)+$").hasMatch(_nameController.text) && _nameController.text != "")) return;
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
                                            const Text("登録内容は正しいですか?"),
                                            const Text("※登録後の変更はできません。", style: TextStyle(color: Colors.red),),
                                            const SizedBox(height: 5,),
                                            _nameController.text != ""? Text("ニックネーム: ${_nameController.text}"): const Text("ニックネーム: (自動生成)"),
                                            Text("メールアドレス: ${_mailController.text}"),
                                            Text("パスワード: ${"*"*_pwController.text.length}"),
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
                                result = await registerAccount();
                                if(result == 1){
                                  if(Navigator.of(context).canPop()){
                                    Navigator.of(context).pop(widget.myData);
                                  }
                                  else{
                                    Navigator.of(context).pushReplacementNamed("/home", arguments: widget.myData);
                                  }
                                }
                                else {
                                  setState((){});
                                }
                              }
                            },
                            child: const Text("登録"),
                          ),
                          const SizedBox(height: 10.0,),
                          Row(
                            children: [
                              const Text("既にアカウントをお持ちの方: ", style: TextStyle(fontSize: 12),),
                              TextButton(
                                child: const Text("ログイン", style: TextStyle(fontSize: 12, color: Colors.blue),),
                                onPressed: () async{
                                  final result = await Navigator.of(context).pushNamed("/login", arguments: widget.myData);
                                  if(Navigator.of(context).canPop()){
                                    Navigator.of(context).pop(result);
                                  }
                                  else{
                                    Navigator.of(context).pushReplacementNamed("/home", arguments: result);
                                  }
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ):
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text("3秒後にホーム画面に遷移します。"),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("遷移しない場合は"),
                        InkWell(
                          onTap: (){
                            Navigator.of(context).pushReplacementNamed("/home");
                          },
                          child: const Text("こちら", style: TextStyle(color: Colors.blue),),
                        ),
                        const Text("を押してください。"),
                      ],
                    ),
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

  Future<int> registerAccount() async{
    _sendName = _nameController.text;
    _sendMail = _mailController.text;
    String pw = _pwController.text;

    setState(() {
      _isLoading = true;
    });

    var pwEncode = sha256.convert(utf8.encode(pw));
    
    //Uri url = Uri.http(serverUrl, phpPath);
    Uri url = Uri.https(serverUrl, phpPath);
    http.MultipartRequest request = http.MultipartRequest("POST", url);
    Map<String, String> map = {
      "mail": _sendMail,
      "pw": pwEncode.toString()
    };
    if(_sendName != ""){
      map.addAll({"name": _sendName});
    }
    request.fields["json"] = json.encode(map);
    request.fields["route"] = "register";

    http.StreamedResponse response = await request.send();

    String result = await response.stream.bytesToString();
    Map<String, dynamic> jsonResponse = jsonDecode(result) as Map<String, dynamic>;

    setState(() {
      _isLoading = false;
    });

    if(response.statusCode != 200){
      _statusCode = response.statusCode;
      if (RegExp(r".*ニックネーム.*").hasMatch(jsonResponse["message"])){
        _statusCode += 1;
      }
      if (RegExp(r".*メールアドレス.*").hasMatch(jsonResponse["message"])){
        _statusCode += 2;
      }
      _message = Text(
        " ${jsonResponse["message"]} (${response.statusCode})",
        style: const TextStyle(color: Colors.red,),
      );
      return 0;
    }
    widget.myData.id = jsonResponse["id"];
    widget.myData.name = jsonResponse["name"];
    return 1;
  }
}
