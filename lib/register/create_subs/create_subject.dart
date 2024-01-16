import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:learning_app/utilities/util.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class CreateSubject extends StatefulWidget {
  const CreateSubject({super.key, this.id, this.data});
  final String? id;
  final Map<dynamic, dynamic>? data;
  @override
  State<CreateSubject> createState() => _CreateSubjectState();
}

class _CreateSubjectState extends State<CreateSubject> {
  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      titleCon.text = widget.data!['subName'];
      descCon.text = widget.data!['subDesc'];
      timeStart.text = widget.data!['subTimeStart'];
      timeEnd.text = widget.data!['subTimeEnd'];
      chosenItem1 = widget.data!['meetingOne'];
      chosenItem2 = widget.data!['meetingTwo'];
    }

    setState(() {
      subjectForm['teacherId'] = userRef.currentUser!.uid;
    });
  }

  final _formKey = GlobalKey<FormState>();
  String? chosenItem1;
  String? chosenItem2;
  TextEditingController timeStart = TextEditingController();
  TextEditingController timeEnd = TextEditingController();
  TextEditingController titleCon = TextEditingController();
  TextEditingController descCon = TextEditingController();
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
        width: MediaQuery.of(context).size.width * .48,
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
    return "00:00 AM";
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
      appBar: AppBar(
          title: Text("${widget.id != null ? 'Edit' : "Create"} Subject")),
      body: SingleChildScrollView(
          child: Form(
              key: _formKey,
              child: Center(
                  child: Column(
                children: [
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: TextFormField(
                          controller: titleCon,
                          decoration: const InputDecoration(
                              labelStyle:
                                  TextStyle(fontWeight: FontWeight.bold),
                              prefixIcon: Icon(Icons.book),
                              labelText: 'Subject Title'),
                          onSaved: (value) {
                            subjectForm["subName"] = value;
                            value = "";
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter Subject Title';
                            }
                            return null;
                          })),
                  Container(
                      margin: const EdgeInsets.only(top: 10),
                      width: MediaQuery.of(context).size.width * 0.9,
                      height: 200,
                      child: TextFormField(
                          controller: descCon,
                          textAlignVertical: TextAlignVertical.top,
                          maxLines: null,
                          expands: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
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
                          })),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    TextButton(
                        style: ButtonStyle(
                            padding:
                                MaterialStateProperty.all(EdgeInsets.zero)),
                        onPressed: () async {
                          timeStart.text = await _showTimePicker() as String;
                        },
                        child: hContainer(TextFormField(
                            onSaved: (value) {
                              subjectForm["subTimeStart"] = value;
                            },
                            controller: timeStart,
                            decoration: InputDecoration(
                                labelStyle: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w500),
                                labelText: 'Start Time',
                                prefixIcon:
                                    const Icon(Icons.access_time_rounded)),
                            enabled: false,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter Start Time';
                              }
                              return null;
                            }))),
                    TextButton(
                        style: ButtonStyle(
                            padding:
                                MaterialStateProperty.all(EdgeInsets.zero)),
                        onPressed: () async {
                          timeEnd.text = await _showTimePicker() as String;
                        },
                        child: hContainer(TextFormField(
                            onSaved: (value) {
                              subjectForm["subTimeEnd"] = value;
                            },
                            controller: timeEnd,
                            decoration: InputDecoration(
                                labelStyle: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w500),
                                labelText: 'Time End',
                                prefixIcon:
                                    const Icon(Icons.access_time_filled)),
                            enabled: false,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter End Time';
                              } else if (timeStart.text == timeEnd.text) {
                                return 'Time should at least be not equal';
                              }
                              return null;
                            }))),
                  ]),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                        margin: EdgeInsets.symmetric(horizontal: 5),
                        width: MediaQuery.of(context).size.width * .45,
                        child: DropdownButtonFormField(
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Set First Meet';
                              } else if (chosenItem1 == chosenItem2) {
                                return 'Days should at least be not equal';
                              }
                              return null;
                            },
                            value: chosenItem1,
                            onSaved: (value) {
                              subjectForm["meetingOne"] = value;
                            },
                            hint: const Text('Set First Meet'),
                            items: [
                              ...items
                                  .map<DropdownMenuItem<String>>((String item) {
                                return DropdownMenuItem<String>(
                                  value: item,
                                  child: Text(item),
                                );
                              })
                            ],
                            onChanged: (value) {
                              setState(() {
                                chosenItem1 = value;
                              });
                            })),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 5),
                      width: MediaQuery.of(context).size.width * .45,
                      child: DropdownButtonFormField(
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Set Second Meet';
                            } else if (chosenItem1 == chosenItem2) {
                              return 'Days should at least be not equal';
                            }
                            return null;
                          },
                          value: chosenItem2,
                          onSaved: (value) {
                            subjectForm["meetingTwo"] = value;
                          },
                          hint: const Text('Set Second Meet'),
                          items: [
                            ...items
                                .map<DropdownMenuItem<String>>((String item) {
                              return DropdownMenuItem<String>(
                                value: item,
                                child: Text(item),
                              );
                            })
                          ],
                          onChanged: (value) {
                            setState(() {
                              chosenItem2 = value;
                            });
                          }),
                    )
                  ]),

                  /*Row(
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
                  ),*/
                ],
              )))),
      persistentFooterButtons: [
        buttonStyle(FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              widget.id != null
                  ? dbRef.child("subjects/${widget.id}").update(subjectForm)
                  : dbRef.child("subjects/").push().set(subjectForm).then((_) {
                      debugPrint(
                          'Data saved with unique ID: ${dbRef.child("subjects/").key}');
                    }).catchError((error) {
                      debugPrint('Error saving data: $error');
                    });
              debugPrint(subjectForm.toString());
            }
          },
          child: Text(
            widget.id != null ? 'Save Changes' : 'Create',
            style: const TextStyle(color: Colors.white, fontSize: 22),
          ),
        )),
      ],
    );
  }
}
