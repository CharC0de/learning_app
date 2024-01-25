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
    getSubjects();

    super.initState();
  }

  StreamSubscription? sessionStream;
  StreamSubscription? subjectStream;
  var sessData = {};
  var subjectData = {};

  List<MapEntry<dynamic, dynamic>> list = [];
  List<MapEntry<dynamic, dynamic>> subList = [];
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
          list.sort(
            (a, b) {
              var sessionDateA =
                  timestampGen(a.value['sessionDate'], 'yyyy-MM-dd HH:mm:ss');
              var sessionDateB =
                  timestampGen(b.value['sessionDate'], 'yyyy-MM-dd HH:mm:ss');
              return sessionDateB.compareTo(sessionDateA);
            },
          );
        });
      }
    });
  }

  getSubjects() {
    subjectStream = dbref
        .child('subjects')
        .orderByChild('teacherId')
        .equalTo(userRef.currentUser!.uid)
        .onValue
        .listen((event) {
      debugPrint(event.snapshot.value.toString());
      if (event.snapshot.value != null) {
        setState(() {
          subjectData = (event.snapshot.value as Map<dynamic, dynamic>)
              .cast<String, dynamic>();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF004B73),
      appBar: AppBar(
        title: const Text('Sessions'),
      ),
      body: ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, int) {
            var id = list[int].key;
            var subjectId = list[int].value['subjectId'];
            var subject = subjectData.entries
                .where((val) => val.key == subjectId)
                .first
                .value['subName'];
            var subData = {};
            var sessionDate = timestampGen(
                list[int].value['sessionDate'], 'yyyy-MM-dd HH:mm:ss');
            return Card(
              child: TextButton(
                  style: ButtonStyle(
                      shape: MaterialStateProperty.all(
                          const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))))),
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
    subjectStream!.cancel();
    super.deactivate();
  }
}
