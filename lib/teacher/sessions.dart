import 'dart:async';

import 'package:flutter/material.dart';
import '../utilities/server_util.dart';
import '../qr/attendance/attendance.dart';
import '../utilities/util.dart';

class SessionData extends StatefulWidget {
  const SessionData({super.key});

  @override
  State<SessionData> createState() => _SessionDataState();
}

class _SessionDataState extends State<SessionData> {
  @override
  initState() {
    getSessions();
    super.initState();
  }

  StreamSubscription? sessionStream;
  var sessData = {};
  List<MapEntry<dynamic, dynamic>> list = [];
  getSessions() {
    sessionStream = dbref
        .child('sessions')
        .orderByChild('teacherId')
        .equalTo(userRef.currentUser!.uid)
        .onValue
        .listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          sessData = (event.snapshot.value as Map<dynamic, dynamic>)
              .cast<String, dynamic>();
          list = sessData.entries
              .where((entry) => entry.value['active'] == false)
              .toList();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sessions'),
      ),
      body: ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, int) {
            var id = list[int].key;
            var subjectId = list[int].value['subjectId'];
            var subject = '';
            var subData = {};
            dbref.child('/subjects/$subjectId').once().then((e) {
              if (e.snapshot.value != null) {
                subData = (e.snapshot.value as Map<dynamic, dynamic>)
                    .cast<String, dynamic>();
                if (context.mounted) {
                  setState(() {
                    subject = subData['subName'];
                  });
                }

                debugPrint(subject);
              }
            });
            var sessionDate = timestampGen(
                list[int].value['sessionDate'], 'yyyy-MM-dd HH:mm:ss');
            return ListTile(
              title: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => AttendancePage(
                            sessId: id, status: list[int].value['status'])));
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text(sessionDate), Text(subject)],
                  )),
            );
          }),
    );
  }

  @override
  void deactivate() {
    sessionStream!.cancel();
    super.deactivate();
  }
}
