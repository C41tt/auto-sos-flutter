import 'package:flutter/material.dart';
import 'menu_page.dart'; // Они в одной папке, так что путь простой

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(), // Сразу ставим темную тему системы
    home: const TestMenuPage(),
  ));
}