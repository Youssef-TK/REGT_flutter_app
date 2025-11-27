import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  double balance = 0.0;
  String language = 'en';

  void updateBalance(double newBalance) {
    balance = newBalance;
    notifyListeners();
  }

  void changeLanguage(String newLang) {
    language = newLang;
    notifyListeners();
  }
}