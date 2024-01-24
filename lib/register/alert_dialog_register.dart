import 'package:flutter/material.dart';

import '../main.dart';

enum DialogAction { done }

class AlertDialogRegister {
  static Future<DialogAction?> showSuccessDialog(
      BuildContext context,
      String title,
      String body,
      ) async {
    final action = await showDialog<DialogAction>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const Login()));
              },
              child: const Text(
                'Done',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    return action;
  }
}
