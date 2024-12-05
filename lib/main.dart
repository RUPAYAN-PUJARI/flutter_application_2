import 'package:flutter/material.dart';
import 'home.dart';

void main() {
  runApp(MyApp());
}

// ignore: use_key_in_widget_constructors
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BHAV-AI',
      theme: ThemeData(
        primarySwatch:Colors.grey,
        brightness:Brightness.dark
      ),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
