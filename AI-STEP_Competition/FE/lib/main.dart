import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'communicate.dart';
import 'home.dart';
import 'register.dart';
import 'login.dart';
import 'upload.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    RankData myData = RankData();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "AI-STEP コンペティション",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale("ja", "JP"),
      ],
      initialRoute: "/home",
      routes: {
        "/home": (context) => HomePage(myData: myData),
        //"/register": (context) => RegisterPage(myData: myData),
        //"/login": (context) => LoginPage(myData: myData),
        //"/upload": (context) => UploadPage(myData: myData),
      },
    );
  }
}
