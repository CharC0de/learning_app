import 'package:flutter/material.dart';

Container inpContainer(Widget widget) {
  return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30), color: Colors.blueGrey[50]),
      child: widget);
}

bool isEmailValidated(String email) {
  RegExp validator = RegExp(r'^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$');
  return validator.hasMatch(email);
}
