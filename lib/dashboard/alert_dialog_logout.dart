import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utilities/server_util.dart';

import '../main.dart';

enum DialogsAction { Yes, Cancel }

class AlertDialogs {
  static Future<DialogsAction> yesCancelDialog(
    BuildContext context,
    String title,
    String body,
  ) async {
    final action = await showDialog<DialogsAction>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const Login()));
              },
              child: const Text(
                'Yes',
                style:
                    TextStyle(color: Colors.blue, fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    return (action != null)
        ? action
        : DialogsAction.Cancel; // Default to Cancel if the dialog is dismissed
  }
}
