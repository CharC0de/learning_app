import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:learning_app/main.dart';
import 'alert_dialog_logout.dart';
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
  bool writeMode = false;
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
    Widget icon = Padding(
        padding: EdgeInsets.only(right: writeMode ? 0 : 5),
        child: Icon(
          Icons.calendar_month,
          color: Theme.of(context).colorScheme.primary,
        ));
    switch (type) {
      case "Start":
        type += " time";
      case "End":
        type += " time";
      default:
        icon;
        break;
    }

    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            Row(
              children: [
                type != "Start time" && type != "End time"
                    ? icon
                    : const SizedBox(),
                Text.rich(TextSpan(children: [
                  TextSpan(
                    text: '$type: ',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  TextSpan(
                      text: time,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface))
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
              shape: MaterialStateProperty.all(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              )),
              padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                EdgeInsets.only(
                    top: 15, bottom: 15, right: writeMode ? 0 : 15, left: 15),
              ),
            ),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => SubjectDashboard(
                      details: data!, id: id!, type: widget.type)));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).primaryColor),
                borderRadius: const BorderRadius.all(Radius.circular(20)),
              ),
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
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.tertiary,
                        fontWeight: FontWeight.w600,
                        fontSize: 30,
                      ),
                    ),
                  ),
                  if (widget.type == "Student")
                    FutureBuilder(
                      future: getTeachPfp(teacherId!),
                      builder: assetBuilder,
                    ),
                  Padding(
                      padding: const EdgeInsets.only(left: 10, bottom: 15),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.access_time_filled),
                            Column(
                              children: [
                                detailValue("Start", start!, context),
                                detailValue("End", end!, context),
                              ],
                            )
                          ])),
                  detailValue(
                    "Meeting Days",
                    meet1! + "s & " + meet2! + "s",
                    context,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.type == "Teacher")
          Visibility(
            visible: writeMode,
            child: Row(children: [
              IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) =>
                          CreateSubject(data: data!, id: id!)));
                },
              ),
              IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.delete),
                onPressed: () {
                  dbRef.child('subjects/$id').remove();
                },
              ),
            ]),
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
      var name =
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(resData["uName"]),
        const Text(
          'Teacher',
          style: TextStyle(color: Colors.blueGrey),
        )
      ]);
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
          name
        ]);
      } else {
        return Row(
          children: [
            const Icon(
              Icons.account_circle,
              size: 35,
            ),
            name
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

  final white = Colors.white;
  Widget editIcon() {
    return FloatingActionButton(
        onPressed: () {
          setState(() {
            writeMode = !writeMode;
          });
        },
        child: const Icon(Icons.edit_square));
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
      ),
      body: hasSubs(item),
      floatingActionButton: editIcon(),
      bottomNavigationBar: BottomAppBar(
          height: 60,
          color: Theme.of(context).appBarTheme.backgroundColor,
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            IconButton(
              color: white,
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const Login()));
              },
              icon: const Icon(Icons.home_filled),
            ),
            widget.type == "Teacher"
                ? Container(
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.inversePrimary,
                        shape: BoxShape.circle),
                    child: IconButton(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) => const CreateSubject())),
                        icon: const Icon(Icons.add)))
                : IconButton(
                    onPressed: () => showDialog<String>(
                        context: context,
                        builder: (context) => chooseSubPopup(context)),
                    icon: const Icon(Icons.add)),
            iconContainer(GestureDetector(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const UserProfile()));
                },
                child: FutureBuilder<Widget>(
                  future: getPfp(),
                  builder: (context, snapshot) =>
                      assetBuilder(context, snapshot),
                )))
          ])),
    );
  }

  @override
  void deactivate() {
    subjStream!.cancel();
    userStream!.cancel();
    super.deactivate();
  }
}
