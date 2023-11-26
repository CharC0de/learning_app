import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:learning_app/utilities/server_util.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen(
      {super.key,
      required this.scannedData,
      required this.details,
      required this.id});
  final dynamic details;
  final String id;
  final String scannedData;
  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  StreamSubscription? sessStream;
  final dbr = FirebaseDatabase.instance.ref();
  @override
  void initState() {
    queryuser();
    initSession();
    super.initState();
  }

  String sessionId = '';
  dynamic sessionDet = {};

  void initSession() {
    sessStream = dbRef
        .child('sessions/')
        .orderByChild('subjectId')
        .equalTo(widget.id)
        .onValue
        .listen((event) {
      setState(() {
        sessionDet = event.snapshot.value;
      });
      debugPrint('sessionDet is null ${sessionDet != null}');
    });
  }

  void createNewSession() {
    setState(() {
      sessionId = dbRef.push().key!;
    });

    final sessionVal = {
      'active': true,
      'teacherId': userRef.currentUser!.uid,
      'subjectId': widget.id,
    };

    dbRef.child('sessions/$sessionId/').set(sessionVal);
  }

  final dbRef = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL:
              "https://learning-app-c8a25-default-rtdb.asia-southeast1.firebasedatabase.app/")
      .ref();
  String admission = "Student does not exist";
  void queryuser() {
    dbRef.child('users/${widget.scannedData}').onValue.listen((event) {
      Map<dynamic, dynamic> users = {};
      if (event.snapshot.value != null) {
        users = (event.snapshot.value as Map<dynamic, dynamic>)
            .cast<String, dynamic>();
      }
      if (users.isNotEmpty) {
        if (users["type"] == 'Student') {
          setState(() {
            admission = 'Admit ${users["uName"]}?';
          });
          // Additional user data can be accessed here if needed
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Result'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Attendance Success',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            Text(
              admission,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
      persistentFooterAlignment: AlignmentDirectional.center,
      persistentFooterButtons: [
        FilledButton(
            onPressed: () {
              if (sessionDet != null) {
                setState(() {
                  sessionDet = (sessionDet as Map<dynamic, dynamic>)
                      .cast<String, dynamic>();
                });
                final filteredSessions = sessionDet.entries
                    .where((entry) => entry.value['active'] == true)
                    .toList();
                debugPrint(filteredSessions.toString());
                if (filteredSessions.isNotEmpty) {
                  setState(() {
                    sessionId = filteredSessions.first.key;
                  });
                  debugPrint('session id0: ${sessionId.toString()}');
                } else {
                  createNewSession();
                  debugPrint('session id1: ${sessionId.toString()}');
                }
              } else {
                createNewSession();
                debugPrint('session id2: ${sessionId.toString()}');
              }
              debugPrint('sessions/$sessionId/students/${widget.scannedData}');
              dbRef
                  .child('sessions/$sessionId/students/${widget.scannedData}')
                  .set(true);

              Navigator.of(context).pop();
            },
            child: SizedBox(
                width: MediaQuery.of(context).size.width / 3,
                child: const Text("Yes", textAlign: TextAlign.center))),
        FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: SizedBox(
                width: MediaQuery.of(context).size.width / 3,
                child: const Text(
                  "No",
                  textAlign: TextAlign.center,
                ))),
      ],
    );
  }

  @override
  @override
  void deactivate() {
    sessStream!.cancel();
    super.deactivate();
  }
}
