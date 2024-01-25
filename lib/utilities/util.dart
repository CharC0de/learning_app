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

bool isUsernameValidated(String username) {
  RegExp validator = RegExp(r'(?![_.])(?!.*[_.]{2})[a-zA-Z0-9._]+(?<![_.])$');
  return validator.hasMatch(username);
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

Widget loading(
  context,
  snapshot,
) {
  if (snapshot.connectionState == ConnectionState.waiting) {
    return const AlertDialog(
      title: CircularProgressIndicator(),
    );
  } else if (snapshot.hasError) {
    return Text('Error: ${snapshot.error}');
  } else {
    return snapshot.data ?? const Text('Image not found');
  }
}
