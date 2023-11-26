import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:learning_app/dashboard/subject_dashboard.dart';
import 'package:learning_app/utilities/util.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class CreateActivity extends StatefulWidget {
  const CreateActivity({
    super.key,
    required this.subjectId,
    required this.details,
    required this.type,
  });
  final String subjectId;
  final String type;
  final dynamic details;

  @override
  State<CreateActivity> createState() => _CreateActivityState();
}

class _CreateActivityState extends State<CreateActivity>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    setState(() {
      assignForm['subjectId'] = widget.subjectId;
      announceForm['subjectId'] = widget.subjectId;
    });
  }

  late final TabController tabController;

  final _announceFormKey = GlobalKey<FormState>();
  final _assignFormKey = GlobalKey<FormState>();

  TextEditingController dlDate = TextEditingController();
  TextEditingController timeEnd = TextEditingController();
  TextEditingController assignType = TextEditingController();
  TextEditingController secondMeet = TextEditingController();
  StreamSubscription? userStream;
  final storeRef = FirebaseStorage.instance.ref();
  final dbRef = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL:
              "https://learning-app-c8a25-default-rtdb.asia-southeast1.firebasedatabase.app/")
      .ref();
  final userRef = FirebaseAuth.instance;

  Map<String, dynamic> assignForm = {
    "assignDesc": "",
    "assignDlDate": "",
    "assignDlTime": "",
    "actType": "assignment",
  };

  DateTime? dlValue;
  Map<String, int> dlDateTime = {
    "year": 0,
    "month": 0,
    "day": 0,
    "hour": 0,
    "minute": 0,
  };
  String? idThingy;
  Map<String, dynamic> announceForm = {
    "annouceDesc": "",
    "announceDate": Timestamp.now().toString(),
    "attachList": [],
    "subjectId": "",
    "actType": "announcement"
  };

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
      setState(() {
        dlDateTime['hour'] = selectedTime.hour;
        dlDateTime['minute'] = selectedTime.minute;
      });

      String time = selectedTime.format(context);
      debugPrint('Selected time: $time');
      return time;
    }
    return "00:00 PM";
  }

  Future<String?> _showDatePickerRTL(BuildContext context) async {
    DateTime currentDate = DateTime.now();
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: currentDate.subtract(
          const Duration(days: 365)), // Adjust the date range as needed
      lastDate: currentDate
          .add(const Duration(days: 365)), // Adjust the date range as needed
      builder: (BuildContext context, Widget? child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      String formattedDate =
          "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}";
      setState(() {
        dlDateTime['year'] = selectedDate.year;
        dlDateTime['month'] = selectedDate.month;
        dlDateTime['day'] = selectedDate.day;
      });
      debugPrint('Selected date: $formattedDate');
      return formattedDate;
    }

    return null;
  }

  List<File> selectedFiles = [];
  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      List<File> files =
          result.files.map((platformFile) => File(platformFile.path!)).toList();

      setState(() {
        selectedFiles = files;

        announceForm["attachList"] =
            selectedFiles.map((file) => file.path.split('/').last).toList();
      });
    }
  }

  Future<void> uploadFiles(String announceId) async {
    for (final file in selectedFiles) {
      final reference = FirebaseStorage.instance
          .ref()
          .child("announcements/$announceId/${file.path.split('/').last}");
      try {
        await reference.putFile(file);
      } catch (e) {
        debugPrint("File Upload Failure due to $e $announceId ");
      }
    }
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
          title: const Text("Create Activity"),
          bottom: TabBar(controller: tabController, tabs: const [
            Icon(Icons.comment),
            Icon(Icons.menu_book),
          ]),
        ),
        body: TabBarView(controller: tabController, children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: Form(
                key: _announceFormKey,
                child: Column(
                  children: [
                    inpContainer(
                      TextFormField(
                          maxLines: 5,
                          decoration: const InputDecoration(
                            alignLabelWithHint: true,
                            labelText: "Announcement Description",
                          ),
                          onSaved: (value) {
                            announceForm["announceDesc"] = value;
                            value = "";
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter Announcement Description';
                            }
                            return null;
                          }),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Add Attachments",
                        style: TextStyle(color: Theme.of(context).hintColor),
                      ),
                    ),
                    SizedBox(
                        width: MediaQuery.of(context).size.width -
                            MediaQuery.of(context).size.width * .05,
                        height: 150,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color: Theme.of(context).hintColor)),
                          child: ListView(
                              children: selectedFiles.isNotEmpty
                                  ? [
                                      const Text(
                                        'Selected Files:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      for (final file
                                          in announceForm["attachList"])
                                        Text(file),
                                    ]
                                  : []),
                        )),
                    Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: pickFiles,
                          child: const Text('Select Files'),
                        )),
                    buttonStyle(FilledButton(
                      onPressed: () {
                        if (_announceFormKey.currentState!.validate()) {
                          _announceFormKey.currentState!.save();

                          final id = dbRef.push().key;
                          dbRef
                              .child("subject_acts/$id")
                              .set(announceForm)
                              .catchError((error) {
                            debugPrint('Error saving data: $error');
                          });
                          uploadFiles(id!);
                        }

                        debugPrint(announceForm.toString());
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => SubjectDashboard(
                                details: widget.details!,
                                id: widget.subjectId,
                                type: widget.type)));
                      },
                      child: const Text(
                        'Submit',
                        style: TextStyle(color: Colors.white, fontSize: 22),
                      ),
                    )),
                  ],
                )),
          ),
          SingleChildScrollView(
            child: Form(
                key: _assignFormKey,
                child: Center(
                    child: Column(
                  children: [
                    inpContainer(
                      TextFormField(
                          decoration:
                              inpDecoration('Assignment Title', Icons.book),
                          onSaved: (value) {
                            assignForm["assignTitle"] = value;
                            value = "";
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter Assignment Title';
                            }
                            return null;
                          }),
                    ),
                    inpContainer(
                      TextFormField(
                          maxLines: 5,
                          decoration: const InputDecoration(
                            alignLabelWithHint: true,
                            labelText: "Assignment Description",
                          ),
                          onSaved: (value) {
                            assignForm["assignDesc"] = value;
                            value = "";
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter Announcement Description';
                            }
                            return null;
                          }),
                    ),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      hContainer(TextFormField(
                          onSaved: (value) {
                            assignForm["assignDlDate"] = value;
                          },
                          controller: dlDate,
                          decoration: inpDecoration(
                              'Deadline Date', Icons.calendar_month),
                          enabled: false,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter Deadline Date';
                            }
                            return null;
                          })),
                      hContainer(TextFormField(
                          onSaved: (value) {
                            assignForm["assignDlTime"] = value;
                          },
                          controller: timeEnd,
                          decoration: inpDecoration(
                              'Deadline Time', Icons.access_time_filled),
                          enabled: false,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter End Time';
                            }
                            return null;
                          })),
                    ]),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      hContainer(FilledButton(
                          onPressed: () async {
                            dlDate.text =
                                await _showDatePickerRTL(context) as String;
                          },
                          child: const Text("Set Date"))),
                      hContainer(FilledButton(
                          onPressed: () async {
                            timeEnd.text = await _showTimePicker() as String;
                          },
                          child: const Text("Set Time"))),
                    ]),
                    buttonStyle(FilledButton(
                      onPressed: () {
                        if (_assignFormKey.currentState!.validate()) {
                          _assignFormKey.currentState!.save();

                          dbRef
                              .child("subject_acts/")
                              .push()
                              .set(assignForm)
                              .then((_) {
                            debugPrint(
                                'Data saved with unique ID: ${dbRef.child("assignjects/").key}');
                          }).catchError((error) {
                            debugPrint('Error saving data: $error');
                          });
                        }
                        debugPrint(assignForm.toString());
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => SubjectDashboard(
                                details: widget.details!,
                                id: widget.subjectId,
                                type: widget.type)));
                      },
                      child: const Text(
                        'Submit',
                        style: TextStyle(color: Colors.white, fontSize: 22),
                      ),
                    )),
                  ],
                ))),
          )
        ]));
  }
}
