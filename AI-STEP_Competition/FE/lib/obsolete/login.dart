import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

import 'dart:convert';

import 'communicate.dart';
import 'setting.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key, required this.myData}) : super(key: key);
  final RankData myData;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _nameOrMailController = TextEditingController();
  final _pwController = TextEditingController();
  bool _obscure = true;
  Text _message = const Text("");
  bool _isLoading = false;
  final FocusNode _nameOrMailFocusNode = FocusNode();
  final FocusNode _pwFocusNode = FocusNode();

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
                            "ログイン",
                            style: TextStyle(fontSize: 24),
                          ),
                          Visibility(
                              visible: _message.data != "",
                              child: _message
                          ),
                          const SizedBox(height: 10.0,),
                          const Text("ニックネームまたはメールアドレス"),
                          Focus(
                            child: SizedBox(
                              width: 300,
                              child: TextFormField(
                                decoration: const InputDecoration(
                                    hintText: "ニックネームかメールアドレスを記載",
                                    border: OutlineInputBorder()
                                ),
                                controller: _nameOrMailController,
                                focusNode: _nameOrMailFocusNode,
                              ),
                            ),
                            onFocusChange: (hasFocus){
                              if(!hasFocus) {
                                setState(() {});
                              } else {
                                _nameOrMailFocusNode.requestFocus();
                              }
                            },
                          ),
                          Visibility(
                            visible: _nameOrMailController.text == "",
                            child: const Text("! ニックネームかメールアドレスを入力してください。", style: TextStyle(color: Colors.red, fontSize: 12),),
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
                                  hintText: "パスワードを入力してください",
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
                                  )
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
                            visible: _pwController.text == "",
                            child: const Text("! パスワードを入力してください。", style: TextStyle(color: Colors.red, fontSize: 12),),
                          ),
                          const SizedBox(height: 10.0,),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(fixedSize: const Size(300, 50)),
                            onPressed: () async{
                              if (_nameOrMailController.text == "" || _pwController.text == "") return;
                              int result = await loginAccount();
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
                            },
                            child: const Text("ログイン"),
                          ),
                          const SizedBox(height: 10.0,),
                          Row(
                            children: [
                              const Text("アカウントをお持ちでない方: ", style: TextStyle(fontSize: 12),),
                              TextButton(
                                child: const Text("新規作成", style: TextStyle(fontSize: 12, color: Colors.blue),),
                                onPressed: () async{
                                  final result = await Navigator.of(context).pushNamed("/register", arguments: widget.myData);
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
                    ),
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

  Future<int> loginAccount() async{
    Map<String, dynamic> parameter = {"route": "login"};
    RegExp(r".*@.*\..*").hasMatch(_nameOrMailController.text)?
        parameter.addAll({"mail": _nameOrMailController.text}):
        parameter.addAll({"name": _nameOrMailController.text});
    String pw = _pwController.text;

    setState(() {
      _isLoading = true;
    });

    var pwEncode = sha256.convert(utf8.encode(pw));
    parameter.addAll({"pw": pwEncode.toString()});

    /*Uri url = Uri.http(
      serverUrl,
      phpPath,
      parameter
    );*/
    Uri url = Uri.https(serverUrl, phpPath, parameter);
    //url = Uri.http("localhost:8001", "/login", parameter);
    http.Response response = await http.get(url);

    String result = utf8.decode(response.bodyBytes);
    Map<String, dynamic> jsonResponse = jsonDecode(result) as Map<String, dynamic>;

    setState(() {
      _isLoading = false;
    });

    if(response.statusCode != 200){
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
