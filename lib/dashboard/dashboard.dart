import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'profile/user_profile.dart';
import '../register/create_subs/create_subject.dart';
import 'subject_dashboard.dart';

class DashBoard extends StatefulWidget {
  const DashBoard({super.key, required this.type});
  final String type;
  @override
  State<DashBoard> createState() => _DashBoardState();
}

class _DashBoardState extends State<DashBoard> {
  bool deleteMode = false;
  List<String> subjectIds = [];

  @override
  void initState() {
    super.initState();
    getUserData();
    getSubs();
  }

  Container buttonStyle(Widget widget) {
    return Container(padding: const EdgeInsets.all(7), child: widget);
  }

  StreamSubscription? userStream;
  StreamSubscription? subjStream;
  StreamSubscription? teachStream;
  final storeRef = FirebaseStorage.instance.ref();
  final dbRef = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL:
              "https://learning-app-c8a25-default-rtdb.asia-southeast1.firebasedatabase.app/")
      .ref();
  final userRef = FirebaseAuth.instance;
  dynamic pfp = "";
  dynamic item = {};

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
    }, onError: (error) {
      // Handle errors during user data retrieval
      debugPrint('Error fetching user data: $error');
    });
  }

  getSubs() {
    debugPrint("${widget.type} what happened");
    final DatabaseReference subjectsRef = dbRef.child('subjects/');

    subjStream = widget.type == "Teacher"
        ? subjectsRef
            .orderByChild("teacherId")
            .equalTo(userRef.currentUser!.uid)
            .onValue
            .listen((event) {
            if (event.snapshot.value != null) {
              final resData = Map<dynamic, dynamic>.from(
                  event.snapshot.value as Map<dynamic, dynamic>);

              setState(() {
                item = resData;
              });
            } else {
              debugPrint("No data");
            }
          }, onError: (error) {
            // Handle errors during subjects data retrieval
            debugPrint('Error fetching subjects data: $error');
          })
        : subjectsRef
            .orderByChild('/users/${userRef.currentUser!.uid}')
            .equalTo(true)
            .onValue
            .listen((event) {
            if (event.snapshot.value != null) {
              final resData = Map<dynamic, dynamic>.from(
                  event.snapshot.value as Map<dynamic, dynamic>);

              setState(() {
                item = resData;
              });
            } else {
              debugPrint("No data");
            }
          }, onError: (error) {
            // Handle errors during subjects data retrieval
            debugPrint('Error fetching subjects data: $error');
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

  Row subjectButton(
    BuildContext context, {
    String? id,
    Map<dynamic, dynamic>? data,
    String? title,
    String? start,
    String? end,
    String? meet1,
    String? meet2,
    String? teacherId,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: TextButton(
            style: ButtonStyle(
              padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                const EdgeInsets.all(5),
              ),
            ),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => SubjectDashboard(
                      details: data!, id: id!, type: widget.type)));
            },
            child: Card(
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
                  Wrap(
                    direction: Axis.vertical,
                    children: [
                      detailValue("Start", start!, context),
                      detailValue("End", end!, context),
                    ],
                  ),
                  detailValue(
                    "Meeting Days",
                    (meet1 == "Thursday"
                            ? "${meet1!.characters.first}h"
                            : meet1!.characters.first) +
                        (meet2 == "Thursday"
                            ? "${meet2!.characters.first}h"
                            : meet2!.characters.first),
                    context,
                  ),
                  if (widget.type == "Student")
                    FutureBuilder(
                        future: getTeachPfp(teacherId!), builder: assetBuilder)
                ],
              ),
            ),
          ),
        ),
        if (widget.type == "Teacher")
          Visibility(
            visible: deleteMode,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              child: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  dbRef.child('subjects/$id').remove();
                },
              ),
            ),
          ),
      ],
    );
  }

  final addSubFormKey = GlobalKey<FormState>();
  String subAddVal = "";
  AlertDialog chooseSubPopup(BuildContext context) => AlertDialog(
        actionsAlignment: MainAxisAlignment.center,
        title: Expanded(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              const Text("Add Subject"),
              GestureDetector(
                  onTap: () => Navigator.pop(context, 'exit'),
                  child: Icon(Icons.cancel_rounded,
                      color: Theme.of(context).colorScheme.primary))
            ])),
        content: const Text("Please input Subject Id here"),
        actions: [
          Form(
              key: addSubFormKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                        hintText: 'Subject ID', labelText: 'Subject ID'),
                    validator: (value) {
                      String? message;
                      dbRef
                          .child('subjects/')
                          .orderByChild("teacherId")
                          .equalTo(userRef.currentUser!.uid)
                          .onValue
                          .listen((event) {
                        if (event.snapshot.value == null) {
                          message = "Subject does not exist";
                        }
                      });
                      return message;
                    },
                    onSaved: (value) {
                      subAddVal = value!;
                    },
                  ),
                  FilledButton(
                      onPressed: () {
                        if (addSubFormKey.currentState!.validate()) {
                          addSubFormKey.currentState!.save();
                          dbRef
                              .child(
                                  'subjects/$subAddVal/users/${userRef.currentUser!.uid}/')
                              .set(true);
                        }
                      },
                      child: const Text('submit'))
                ],
              ))
        ],
      );

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

      if (teachPic != null) {
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
            child: Text(resData["uName"]),
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
              child: Text(resData["uName"]),
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

  Widget hasSubs(items) {
    return items != null
        ? ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final subjectId = items.keys.elementAt(index);
              final subjectData = items[subjectId];

              // Add the subject ID to the list
              subjectIds.add(subjectId);

              return subjectButton(context,
                  id: subjectId,
                  data: subjectData,
                  title: subjectData['subName'],
                  start: subjectData['subTimeStart'],
                  end: subjectData['subTimeEnd'],
                  meet1: subjectData['meetingOne'],
                  meet2: subjectData['meetingTwo'],
                  teacherId: widget.type == 'Student'
                      ? subjectData['teacherId']
                      : null);
            },
          )
        : const Center(
            child: Text("You currently have no subjects"),
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text("Subjects"),
          actions: [
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
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const Login()));
              },
              icon: const Icon(Icons.logout_outlined),
            )
          ],
        ),
        body: hasSubs(item),
        persistentFooterAlignment: AlignmentDirectional.center,
        persistentFooterButtons: [
          widget.type == "Teacher"
              ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  buttonStyle(SizedBox(
                    width: MediaQuery.of(context).size.width / 2.3,
                    child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => const CreateSubject()));
                        },
                        child: const Text(
                          "Add Subject",
                          style: TextStyle(fontSize: 16),
                        )),
                  )),
                  buttonStyle(SizedBox(
                    width: MediaQuery.of(context).size.width / 2.3,
                    child: FilledButton(
                        onPressed: () {
                          setState(() {
                            deleteMode = !deleteMode;
                          });
                        },
                        child: const Text(
                          "Edit Subject",
                          style: TextStyle(fontSize: 16),
                        )),
                  ))
                ])
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  buttonStyle(SizedBox(
                    width: MediaQuery.of(context).size.width -
                        MediaQuery.of(context).size.width * .25,
                    child: FilledButton(
                        onPressed: () {
                          showDialog<String>(
                              context: context,
                              builder: (context) => chooseSubPopup(context));
                        },
                        child: const Text(
                          "Add Subject",
                          style: TextStyle(fontSize: 16),
                        )),
                  )),
                ])
        ]);
  }

  @override
  void deactivate() {
    subjStream!.cancel();
    userStream!.cancel();
    super.deactivate();
  }
}
