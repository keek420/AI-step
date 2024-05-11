import 'package:flutter/material.dart';

import 'communicate.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.myData}) : super(key: key);
  final RankData myData;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Text message = const Text("");
  Text _mymes = const Text("");
  RankDataList rankDataList = RankDataList();
  final List<bool> _appbarTextButtonFocus = [false, false, false, false];

  @override
  void initState() {
    super.initState();
    //widget.myData.showData();
    if(rankDataList.errorStr != ""){
      message = Text(
        rankDataList.errorStr,
        style: const TextStyle(fontSize: 20),
      );
    }
    Future(() async{
      await rankDataList.getRankDataList();
      if(widget.myData.id > 0){
        String? result = await widget.myData.getRankData();
        if(result != null){
          _mymes = Text(
            result,
            style: const TextStyle(fontSize: 20),
          );
        }
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    //MediaQueryData mediaQueryData = MediaQuery.of(context);
    //print(mediaQueryData.size.width);
    Set<String> seenNames = Set<String>();//名前一覧
    Set<String> duplicateNames = Set<String>();//重複のある名前のset

    for (RankData rankData in rankDataList.rankDataList) {
      if (!seenNames.add(rankData.name)) {
        // すでにセットに存在する名前は重複としてマーク
          duplicateNames.add(rankData.name);
      }
    }
    for(RankData rankData in rankDataList.rankDataList){
      rankData.showData();
    }
    return Scaffold(
      appBar: appbar(),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Container(
          margin: const EdgeInsets.all(10.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 20.0,),
                const Text("全体ランキング",),
                message.data == ""?
                SingleChildScrollView(
                  
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    dataRowMinHeight: 48.0,
                    dataRowMaxHeight: 60.0,
                    columns: const <DataColumn>[
                      DataColumn(label: Text("順位")),
                      DataColumn(label: Text("ニックネーム")),
                      DataColumn(label: Text("スコア(%)")),
                      DataColumn(label: Text("提出日時")),
                      DataColumn(label: Text("エラーメッセージ")),
                    ],
                    rows: <DataRow>[
                      for(RankData rankData in rankDataList.rankDataList)
                        DataRow(
                            cells: [
                              DataCell(Text(rankData.rank.toString())),
                              DataCell(
                                duplicateNames.contains(rankData.name)
                                ? RichText(
                                    text: TextSpan(
                                      text: "ニックネームが重複しています\n",
                                      style: TextStyle(color: Colors.red),
                                      children: <TextSpan>[
                                        TextSpan(
                                          text: rankData.name,
                                          style: TextStyle(color:  Colors.black),
                                          ),
                                        ],
                                      )
                                    )
                                : Text(rankData.name),
                              ),
                              DataCell(Text(rankData.ans)),
                              DataCell(Text(rankData.time)),
                              DataCell(
                                Container(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (rankData.is_error)
                                        Column(
                                          children: [
                                            const Text(
                                              "最新の提出は正常に採点されませんでした。",
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  _showDetailDialog(context, rankData.error_msg);
                                                },
                                                child: const Text(
                                                  "エラー詳細"),
                                              )
                                          ],
                                        )
                                      else
                                        Text(""), // エラーでない場合は空のテキストを表示
                                    ],
                                  ),
                                ),
                              )
                          ]
                        ),
                      
                    ],
                  ),
                ):
                message,
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar appbar(){
    return AppBar(
      title: const Text("AI-STEP コンペティション"),
      titleTextStyle: const TextStyle(color: Colors.white, fontSize: 32),
      backgroundColor: Colors.black,
    );
  }

  Future<void> updateData(RankData data) async{
    widget.myData.id = data.id;
    widget.myData.name = data.name;
    await widget.myData.getRankData();
    await rankDataList.getRankDataList();
    setState(() {});
  }
}

void _showDetailDialog(BuildContext context, String detail) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('詳細情報'),
        content: Text(detail),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('閉じる'),
          ),
        ],
      );
    },
  );
}