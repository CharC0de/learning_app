import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:learning_app/utilities/server_util.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key, required this.sessId, this.status});
  final String sessId;
  final bool? status;
  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  StreamSubscription? attendStream;
  @override
  initState() {
    getAttend();
    super.initState();
  }

  dynamic attendData = {};
  void getAttend() {
    attendStream = dbref
        .child('/sessions/${widget.sessId}/students/')
        .onValue
        .listen((event) {
      if (context.mounted) {
        if (event.snapshot.value != null) {
          setState(() {
            attendData = event.snapshot.value;
          });
        }
      }
      debugPrint('$attendData');
    });
  }

  Future<Widget> getStudPfp(String studentId) async {
    try {
      dynamic studPic = "";
      dynamic uname = "";
      dynamic resData;

      if (userRef.currentUser != null) {
        DataSnapshot snapshot = await dbref.child('users/$studentId/').get();
        if (snapshot.value != null) {
          resData =
              (snapshot.value as Map<dynamic, dynamic>).cast<String, dynamic>();
          studPic = resData["pfp"];
          uname = resData["uName"];
        }
      }

      if (studPic != null) {
        final ref = FirebaseStorage.instance.ref().child("$studentId/$studPic");
        final url = await ref.getDownloadURL();
        return Row(children: [
          Container(
              margin: const EdgeInsets.all(6),
              child: SizedBox(
                width: 35,
                height: 35,
                child: CircleAvatar(
                  radius: 100,
                  backgroundImage: NetworkImage(url),
                ),
              )),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            child: Text(uname),
          ),
        ]);
      } else {
        return Row(
          children: [
            const Icon(
              Icons.account_circle,
              size: 35,
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              child: Text(uname),
            ),
          ],
        );
      }
    } catch (e) {
      debugPrint('Error getting teacher profile picture: $e');
      // Handle error gracefully, maybe show a default avatar
      return const Icon(
        Icons.account_circle,
        size: 35,
      );
    }
  }

  Widget assetBuilder(context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Card();
    } else if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    } else {
      return snapshot.data ?? const Text('Image not found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Session Attendance List'),
        ),
        body: attendData.keys.length > 0 || attendData != null
            ? ListView.builder(
                itemCount: attendData.keys.length,
                itemBuilder: (context, index) {
                  final studId = attendData.keys.elementAt(index);
                  return ListTile(
                      title: FutureBuilder(
                          future: getStudPfp(studId), builder: assetBuilder));
                })
            : const Center(
                child: Text('No one Has Attended yet'),
              ),
        persistentFooterAlignment: AlignmentDirectional.center,
        persistentFooterButtons: widget.status == null
            ? [
                FilledButton(
                    onPressed: () async {
                      await dbref
                          .child('sessions/${widget.sessId}/active/')
                          .set(false);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('End Session'))
              ]
            : null);
  }

  @override
  void deactivate() {
    attendStream!.cancel();
    super.deactivate();
  }
}
