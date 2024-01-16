import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

String timestampGen(date, format) {
  return DateFormat(format).format(
    DateTime.fromMicrosecondsSinceEpoch(
      int.parse(
            RegExp(r'seconds=(\d+), nanoseconds=(\d+)')
                    .firstMatch(date ?? "Timestamp(seconds=0, nanoseconds=0)")!
                    .group(1)! +
                RegExp(r'seconds=(\d+), nanoseconds=(\d+)')
                    .firstMatch(date ?? "Timestamp(seconds=0, nanoseconds=0)")!
                    .group(2)!,
          ) ~/
          1000,
    ),
  );
}
