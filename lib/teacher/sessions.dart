import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
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
    getSub();
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
          debugPrint(list.toString());
          list.sort((a, b) => timestampGen(
                  b.value['sessionDate'], 'yyyy-MM-dd HH:mm:ss')
              .compareTo(
                  timestampGen(a.value['sessionDate'], 'yyyy-MM-dd HH:mm:ss')));
          debugPrint(list.toString());
        });
      }
    });
  }

  void getSub() async {
    DataSnapshot val = await dbref.child('/subjects/').get();
    var data = (val.value as Map<dynamic, dynamic>).cast<String, dynamic>();
    setState(() {
      subjects = data;
    });
    debugPrint(data.toString());
  }

  var subjects = {};

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
            var subjectData = Map.fromEntries(
                subjects.entries.where((element) => element.key == subjectId));
            var subject = subjectData[subjectId]['subName'];
            var sessionDate = timestampGen(
                list[int].value['sessionDate'], 'yyyy-MM-dd HH:mm:ss');
            return ListTile(
                title: TextButton(
              style: ButtonStyle(
                  shape: MaterialStateProperty.all(const BeveledRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5))))),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => AttendancePage(
                        sessId: id, status: list[int].value['active'])));
              },
              child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      border:
                          Border.all(color: Theme.of(context).primaryColor)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text(sessionDate), Text(subject)],
                  )),
            ));
          }),
    );
  }

  @override
  void deactivate() {
    sessionStream!.cancel();

    super.deactivate();
  }
}
