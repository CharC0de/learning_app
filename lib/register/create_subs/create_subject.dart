import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:learning_app/utilities/util.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class CreateSubject extends StatefulWidget {
  const CreateSubject({super.key});
  @override
  State<CreateSubject> createState() => _CreateSubjectState();
}

class _CreateSubjectState extends State<CreateSubject> {
  @override
  void initState() {
    super.initState();

    setState(() {
      subjectForm['teacherId'] = userRef.currentUser!.uid;
    });
  }

  final _formKey = GlobalKey<FormState>();
  TextEditingController timeStart = TextEditingController();
  TextEditingController timeEnd = TextEditingController();
  TextEditingController firstMeet = TextEditingController();
  TextEditingController secondMeet = TextEditingController();
  StreamSubscription? userStream;
  final storeRef = FirebaseStorage.instance.ref();
  final dbRef = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL:
              "https://learning-app-c8a25-default-rtdb.asia-southeast1.firebasedatabase.app/")
      .ref();
  final userRef = FirebaseAuth.instance;

  Map<String, dynamic> subjectForm = {
    "subName": "",
    "subDesc": "",
    "subTimeStart": "",
    "subTimeEnd": "",
    "meetingOne": "",
    "meetingTwo": "",
    "teacherId": "",
  };
  final List<String> items = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  SizedBox hContainer(Widget widget) {
    return SizedBox(
        width: MediaQuery.of(context).size.width / 2.1,
        child: Container(margin: const EdgeInsets.all(5), child: widget));
  }

  Container buttonStyle(Widget widget) => Container(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 18),
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 18),
          child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 50,
              child: widget)));

  Future<String?> _showTimePicker() async {
    Future<TimeOfDay?> selectedTimeRTL = showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );
    TimeOfDay? selectedTime = await selectedTimeRTL;
    if (selectedTime != null) {
      String time = selectedTime.format(context);
      debugPrint('Selected time: $time');
      return time;
    }
    return "00:00 PM";
  }

  InputDecoration inpDecoration(String identifier, IconData? icon) =>
      InputDecoration(
        prefixIcon: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        hintText: identifier,
        labelText: identifier,
      );
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Create Subject")),
        body: SingleChildScrollView(
          child: Form(
              key: _formKey,
              child: Center(
                  child: Column(
                children: [
                  inpContainer(
                    TextFormField(
                        decoration: inpDecoration('Subject Title', Icons.book),
                        onSaved: (value) {
                          subjectForm["subName"] = value;
                          value = "";
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter Subject Title';
                          }
                          return null;
                        }),
                  ),
                  inpContainer(
                    TextFormField(
                        maxLines: 5,
                        decoration: const InputDecoration(
                          alignLabelWithHint: true,
                          labelText: "Subject Description",
                        ),
                        onSaved: (value) {
                          subjectForm["subDesc"] = value;
                          value = "";
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter Subject Description';
                          }
                          return null;
                        }),
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    hContainer(TextFormField(
                        onSaved: (value) {
                          subjectForm["subTimeStart"] = value;
                        },
                        controller: timeStart,
                        decoration: inpDecoration(
                            'Start Time', Icons.access_time_rounded),
                        enabled: false,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter Start Time';
                          }
                          return null;
                        })),
                    hContainer(TextFormField(
                        onSaved: (value) {
                          subjectForm["subTimeEnd"] = value;
                        },
                        controller: timeEnd,
                        decoration:
                            inpDecoration('Time End', Icons.access_time_filled),
                        enabled: false,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter End Time';
                          } else if (timeStart.text == timeEnd.text) {
                            return 'Time should at least be not equal';
                          }
                          return null;
                        })),
                  ]),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    hContainer(FilledButton(
                        onPressed: () async {
                          timeStart.text = await _showTimePicker() as String;
                        },
                        child: const Text("Set start"))),
                    hContainer(FilledButton(
                        onPressed: () async {
                          timeEnd.text = await _showTimePicker() as String;
                        },
                        child: const Text("Set end"))),
                  ]),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    hContainer(TextFormField(
                        onSaved: (value) {
                          subjectForm["meetingOne"] = value;
                        },
                        controller: firstMeet,
                        decoration:
                            inpDecoration('First Meet', Icons.school_outlined),
                        enabled: false,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Set First Meet';
                          }
                          return null;
                        })),
                    hContainer(TextFormField(
                        onSaved: (value) {
                          subjectForm["meetingTwo"] = value;
                        },
                        controller: secondMeet,
                        decoration: inpDecoration('Second Meet', Icons.school),
                        enabled: false,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Set Second Meet';
                          } else if (secondMeet.text == firstMeet.text) {
                            return 'Days should at least be not equal';
                          }
                          return null;
                        })),
                  ]),
                  Row(
                    children: [
                      hContainer(Column(
                        children: [
                          DropdownButton<String>(
                              value: firstMeet.text = "Monday",
                              onChanged: (String? newValue) {
                                firstMeet.text = newValue!;
                              },
                              items: items
                                  .map<DropdownMenuItem<String>>((String item) {
                                return DropdownMenuItem<String>(
                                  value: item,
                                  child: Text(item),
                                );
                              }).toList())
                        ],
                      )),
                      hContainer(Column(
                        children: [
                          DropdownButton<String>(
                              value: secondMeet.text = "Monday",
                              onChanged: (String? newValue) {
                                secondMeet.text = newValue!;
                              },
                              items: items
                                  .map<DropdownMenuItem<String>>((String item) {
                                return DropdownMenuItem<String>(
                                  value: item,
                                  child: Text(item),
                                );
                              }).toList())
                        ],
                      ))
                    ],
                  ),
                  buttonStyle(FilledButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        dbRef
                            .child("subjects/")
                            .push()
                            .set(subjectForm)
                            .then((_) {
                          debugPrint(
                              'Data saved with unique ID: ${dbRef.child("subjects/").key}');
                        }).catchError((error) {
                          debugPrint('Error saving data: $error');
                        });
                        debugPrint(subjectForm.toString());
                      }
                    },
                    child: const Text(
                      'Register',
                      style: TextStyle(color: Colors.white, fontSize: 22),
                    ),
                  )),
                ],
              ))),
        ));
  }
}
