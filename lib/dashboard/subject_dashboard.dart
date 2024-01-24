import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:learning_app/qr/res_screen.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../main.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'alert_dialog_logout.dart';
import 'profile/user_profile.dart';
import '../register/create_subs/create_sub_act.dart';
import '../qr/qr_scanner.dart';
import '../qr/qr_generator.dart';
import '../register/assignment.dart';

class SubjectDashboard extends StatefulWidget {
  const SubjectDashboard(
      {super.key, required this.details, required this.id, required this.type});
  final Map<dynamic, dynamic> details;
  final String id;
  final String type;
  @override
  State<SubjectDashboard> createState() => _SubjectDashboardState();
}

class _SubjectDashboardState extends State<SubjectDashboard> {
  bool deleteMode = false;
  List<String> subjectIds = [];
  @override
  void initState() {
    getUserData();
    getActs();
    super.initState();
  }

  Container buttonStyle(Widget widget) {
    return Container(padding: const EdgeInsets.all(7), child: widget);
  }

  void _launchURL(String url) async {
    // Encode the URL
    try {
      launchUrlString(url);
    } catch (e) {
      debugPrint("$e");
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied Subject ID to clipboard: ${widget.id}'),
      ),
    );
  }

  StreamSubscription? userStream;
  StreamSubscription? subjStream;
  StreamSubscription? actStream;
  final storeRef = FirebaseStorage.instance.ref();
  final dbRef = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL:
              "https://learning-app-c8a25-default-rtdb.asia-southeast1.firebasedatabase.app/")
      .ref();
  final userRef = FirebaseAuth.instance;
  dynamic pfp = "";
  dynamic actData = {};

  getActs() {
    actStream = dbRef
        .child('subject_acts/')
        .orderByChild("subjectId")
        .equalTo(widget.id)
        .onValue
        .listen((event) {
      if (event.snapshot.value != null) {
        final resData = Map<dynamic, dynamic>.from(
            event.snapshot.value as Map<dynamic, dynamic>);
        debugPrint(resData.toString());
        setState(() {
          List<MapEntry<dynamic, dynamic>> sortedMap = resData.entries.toList();

          sortedMap.sort((a, b) =>
              b.value['announceDate'].compareTo(a.value['announceDate']));

          actData = Map.fromEntries(sortedMap);
        });
      } else {
        debugPrint("No data");
      }
    });
  }

  getUserData() {
    userStream = dbRef
        .child('users/${userRef.currentUser!.uid}/')
        .onValue
        .listen((event) {
      if (event.snapshot.value != null) {
        final resData = (event.snapshot.value as Map<dynamic, dynamic>)
            .cast<String, dynamic>();
        setState(() {
          pfp = resData["pfp"];
        });
      }
    });
  }

  Container iconContainer(Widget child) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: child,
    );
  }

  Container detailValue(String type, String time, context) {
    IconData? icon;
    switch (type) {
      case "Start":
        type += " time";
        icon = Icons.access_time;
      case "End":
        type += " time";
        icon = Icons.access_time_filled;
      default:
        icon = Icons.calendar_month;
        break;
    }

    return Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        child: Row(
          children: [
            Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                )),
            Row(
              children: [
                Text.rich(TextSpan(children: [
                  TextSpan(
                    text: '$type: ',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  TextSpan(text: time)
                ]))
              ],
            )
          ],
        ));
  }

  Container textValue(String type, String time, context) {
    IconData? icon;
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        child: Row(
          children: [
            Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                )),
            Row(
              children: [
                Text.rich(TextSpan(children: [
                  TextSpan(
                    text: '$type: ',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  TextSpan(text: time)
                ]))
              ],
            )
          ],
        ));
  }

  Expanded subjectInfo(
    BuildContext context, {
    String? title,
    String? desc,
    String? start,
    String? end,
    String? meet1,
    String? meet2,
  }) {
    return Expanded(
        child: Container(
      decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).primaryColor),
          borderRadius: const BorderRadius.all(Radius.circular(20))),
      margin: const EdgeInsets.only(top: 5, left: 10, right: 10, bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 5,
                horizontal: 10,
              ),
              child: Text(
                title!,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 30,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 5,
                horizontal: 10,
              ),
              child: Text(
                desc!,
              ),
            ),
            Wrap(
              direction: Axis.horizontal,
              children: [
                detailValue("Start", start!, context),
                detailValue("End", end!, context),
                detailValue(
                  "Meeting Days",
                  "$meet1 and $meet2",
                  context,
                )
              ],
            ),
          ],
        ),
      ),
    ));
  }

  Expanded assignButton(
    BuildContext context, {
    String? id,
    String? title,
    String? desc,
    String? deadline,
    String? date,
  }) {
    return Expanded(
      child: TextButton(
        style: ButtonStyle(
          shape: MaterialStateProperty.all(RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20.0), // Adjust the radius as needed
          )),
          padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
            const EdgeInsets.all(10),
          ),
        ),
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => AssignmentForm(
                  type: widget.type,
                  id: id!,
                  title: title,
                  desc: desc,
                  deadline: deadline)));
          debugPrint("$id");
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 150),
          decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).primaryColor),
              borderRadius: const BorderRadius.all(Radius.circular(20))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  child: Row(children: [
                    Icon(Icons.book,
                        color: Theme.of(context).colorScheme.onSurface),
                    Text(
                      'Assignment',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                    )
                  ]),
                ),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      DateFormat('yyyy-MM-dd HH:mm').format(
                        DateTime.fromMicrosecondsSinceEpoch(
                          int.parse(
                                RegExp(r'seconds=(\d+), nanoseconds=(\d+)')
                                        .firstMatch(date ??
                                            "Timestamp(seconds=0, nanoseconds=0)")!
                                        .group(1)! +
                                    RegExp(r'seconds=(\d+), nanoseconds=(\d+)')
                                        .firstMatch(date ??
                                            "Timestamp(seconds=0, nanoseconds=0)")!
                                        .group(2)!,
                              ) ~/
                              1000,
                        ),
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    )),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 5,
                  horizontal: 15,
                ),
                child: Text(
                  title!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              Padding(
                  padding: const EdgeInsets.all(5),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    child: Text(
                      desc!,
                      style: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.normal),
                    ),
                  )),
              detailValue("Deadline", deadline!, context),
            ],
          ),
        ),
      ),
    );
  }

  Widget announcement(
    BuildContext context, {
    String? date,
    String? desc,
    String? id,
    dynamic list,
    String? teachId,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 150),
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          border: Border.all(color: Theme.of(context).primaryColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.type == 'Student'
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                      FutureBuilder(
                          future: getTeachPfp(teachId!), builder: assetBuilder),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        child: Text(
                          DateFormat('yyyy-MM-dd').format(
                            DateTime.fromMicrosecondsSinceEpoch(
                              int.parse(
                                    RegExp(r'seconds=(\d+), nanoseconds=(\d+)')
                                            .firstMatch(date ??
                                                "Timestamp(seconds=0, nanoseconds=0)")!
                                            .group(1)! +
                                        RegExp(r'seconds=(\d+), nanoseconds=(\d+)')
                                            .firstMatch(date ??
                                                "Timestamp(seconds=0, nanoseconds=0)")!
                                            .group(2)!,
                                  ) ~/
                                  1000,
                            ),
                          ),
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.primary),
                        ),
                      )
                    ])
              : Row(children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    child: Text(
                      DateFormat('yyyy-MM-dd HH:mm:ss').format(
                        DateTime.fromMicrosecondsSinceEpoch(
                          int.parse(
                                RegExp(r'seconds=(\d+), nanoseconds=(\d+)')
                                        .firstMatch(date ??
                                            "Timestamp(seconds=0, nanoseconds=0)")!
                                        .group(1)! +
                                    RegExp(r'seconds=(\d+), nanoseconds=(\d+)')
                                        .firstMatch(date ??
                                            "Timestamp(seconds=0, nanoseconds=0)")!
                                        .group(2)!,
                              ) ~/
                              1000,
                        ),
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  )
                ]),
          Padding(
            padding: const EdgeInsets.all(5),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: Text(desc ?? ""),
            ),
          ),
          if (list != null)
            Visibility(
              visible: list.isNotEmpty,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Attachments:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    for (final file in list)
                      TextButton(
                        style: ButtonStyle(
                          shape:
                              MaterialStateProperty.all(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          )),
                          padding:
                              MaterialStateProperty.all<EdgeInsetsGeometry>(
                            const EdgeInsets.all(1),
                          ),
                        ),
                        onPressed: () async {
                          final url = await storeRef
                              .child("announcements/$id/$file")
                              .getDownloadURL();
                          _launchURL(url);
                        },
                        child: Text(
                          file,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<Widget> getPfp() async {
    if (pfp != null && userRef.currentUser != null) {
      debugPrint(userRef.currentUser!.uid);
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child("${userRef.currentUser!.uid}/$pfp");
        final url = await ref.getDownloadURL();
        return SizedBox(
          width: 35,
          height: 35,
          child: CircleAvatar(
            radius: 100,
            backgroundImage: NetworkImage(url),
          ),
        );
      } catch (e) {
        debugPrint('Error getting profile picture: $e');
        // Handle error gracefully, maybe show a default avatar
      }
    }

    debugPrint('noPfp');
    return const Icon(
      Icons.account_circle,
      size: 35,
    );
  }

  Future<Widget> getTeachPfp(String teacherId) async {
    try {
      dynamic teachPic = "";
      String uname = "";
      dynamic resData;

      if (userRef.currentUser != null) {
        debugPrint('***********');

        DataSnapshot snapshot = await dbRef.child('users/$teacherId/').get();
        if (snapshot.value != null) {
          resData =
              (snapshot.value as Map<dynamic, dynamic>).cast<String, dynamic>();
          teachPic = resData["pfp"];
          uname = resData["uName"];
        }
      }

      if (teachPic.isNotEmpty) {
        final ref =
            FirebaseStorage.instance.ref().child("$teacherId/$teachPic");
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
      return const CircularProgressIndicator();
    } else if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    } else {
      return snapshot.data ?? const Text('Image not found');
    }
  }

  final wordButton = ButtonStyle(
    shape: MaterialStateProperty.all(RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10.0), // Adjust the radius as needed
    )),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          centerTitle: widget.details["subName"].length > 15 ? false : true,
          title: widget.type == "Teacher"
              ? Row(children: [
                  Text(
                    widget.details["subName"]!,
                    style: TextStyle(
                        fontSize: widget.details["subName"].length > 15
                            ? 20 - widget.details["subName"].length + 13
                            : 20),
                  ),
                ])
              : Text(widget.details["subName"]!),
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: IconButton(
                  onPressed: _copyToClipboard, icon: const Icon(Icons.share)),
            ),
            iconContainer(GestureDetector(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const UserProfile()));
                },
                child: FutureBuilder<Widget>(
                  future: getPfp(),
                  builder: (context, snapshot) =>
                      assetBuilder(context, snapshot),
                ))),
            IconButton(
                onPressed: () async {
                  //   FirebaseAuth.instance.signOut();
                  //   Navigator.of(context)
                  //       .push(MaterialPageRoute(builder: (context) => const Login()));
                  // },
                  // icon: const Icon(Icons.logout_outlined),
                  final action = await AlertDialogs.yesCancelDialog(
                      context, 'Logout', 'Are you sure?');
                },
                icon: const Icon(Icons.logout_outlined))
          ]),
      body: ListView.builder(
          itemCount: actData.length + 1,
          itemBuilder: (context, index) {
            dynamic actId;
            dynamic actval;
            if (actData.keys.length > 0 && index > 0) {
              actId = actData.keys.elementAt(index - 1);
              actval = actData[actId];
            }

            return index == 0
                ? subjectInfo(
                    context,
                    title: widget.details['subName'],
                    desc: widget.details['subDesc'],
                    start: widget.details['subTimeStart'],
                    end: widget.details['subTimeEnd'],
                    meet1: widget.details['meetingOne'],
                    meet2: widget.details['meetingTwo'],
                  )
                : actval != null && actval['actType'] == 'assignment'
                    ? assignButton(
                        context,
                        id: actId,
                        title: actval["assignTitle"],
                        desc: actval["assignDesc"],
                        deadline: actval["assignDlDate"] +
                            " " +
                            actval["assignDlTime"],
                        date: actval["announceDate"],
                      )
                    : actval != null && actval['actType'] == 'announcement'
                        ? announcement(context,
                            date: actval["announceDate"],
                            desc: actval["announceDesc"],
                            id: actId,
                            list: actval["attachList"] != null
                                ? actval["attachList"]
                                    .map((item) => item.toString())
                                    .toList()!
                                : [],
                            teachId: widget.details['teacherId'])
                        : const SizedBox.shrink();
          }),
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => CreateActivity(
                    subjectId: widget.id,
                    details: widget.details,
                    type: widget.type)));
          },
          child: const Icon(Icons.add)),
      bottomNavigationBar: BottomAppBar(
          padding: EdgeInsets.zero,
          height: 50,
          child: Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                widget.type == "Teacher"
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            TextButton(
                                style: wordButton,
                                onPressed: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (context) => QRCodeScannerPage(
                                          id: widget.id,
                                          details: widget.details)));
                                },
                                child: const Text(
                                  "Start Session",
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                )),
                          ])
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Expanded(
                              child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            QrCodeScreen(id: widget.id),
                                      ),
                                    );
                                  },
                                  child: const Column(children: [
                                    Padding(
                                        padding: EdgeInsets.all(2),
                                        child: Icon(Icons.qr_code)),
                                    Text(
                                      "Generate ID QR",
                                      style: TextStyle(fontSize: 16),
                                    )
                                  ])),
                            ),
                          ])
              ],
            ),
          )),
    );
  }
}
