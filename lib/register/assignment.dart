import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:learning_app/utilities/server_util.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AssignmentForm extends StatefulWidget {
  const AssignmentForm({
    super.key,
    required this.id,
    required this.type,
    required this.title,
    required this.desc,
    required this.deadline,
  });
  final String title;
  final String type;
  final String desc;
  final String id;
  final String deadline;
  @override
  State<AssignmentForm> createState() => _AssignmentFormState();
}

class _AssignmentFormState extends State<AssignmentForm> {
  @override
  void initState() {
    getResponse();
    super.initState();
  }

  StreamSubscription? respStream;
  TextEditingController commentController = TextEditingController();
  final inpFormKey = GlobalKey<FormState>();
  Map<String, dynamic> inpForm = {
    "inpComment": "",
    "inpStamp": DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
    "inpAttachList": [],
  };
  bool hasError = false;
  String error = "";
  List<File> selectedFiles = [];
  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      List<File> files =
          result.files.map((platformFile) => File(platformFile.path!)).toList();

      setState(() {
        selectedFiles = files;

        inpForm["inpAttachList"] =
            selectedFiles.map((file) => file.path.split('/').last).toList();
      });
    }
  }

  Future<void> uploadFiles(String announceId) async {
    for (final file in selectedFiles) {
      final reference = FirebaseStorage.instance.ref().child(
          "assignments/$announceId/${userRef.currentUser!.uid}/${file.path.split('/').last}");
      try {
        await reference.putFile(file);
      } catch (e) {
        debugPrint("File Upload Failure due to $e $announceId ");
      }
    }
  }

  bool hasSubmitted = false;

  dynamic respoData = {};
  void getResponse() {
    respStream = dbref
        .child('/subject_acts/${widget.id}/responses/')
        .onValue
        .listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          respoData = event.snapshot.value;
        });
      }
      debugPrint('$respoData');
    });
  }

  Future<Widget> getStudPfp(String studentId) async {
    try {
      String studPic = "";
      String uname = "";
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

      if (studPic.isNotEmpty) {
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
      return const CircularProgressIndicator();
    } else if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    } else {
      return snapshot.data ?? const Text('Image not found');
    }
  }

  void _launchURL(String url) async {
    // Encode the URL
    try {
      launchUrlString(url);
    } catch (e) {
      debugPrint("$e");
    }
  }

  Container response(
    BuildContext context, {
    String? date,
    String? comment,
    dynamic list,
    String? studId,
  }) {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          border: Border.all(color: Theme.of(context).primaryColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FutureBuilder(
                    future: getStudPfp(studId!), builder: assetBuilder),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: Text(
                    date!,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.primary),
                  ),
                )
              ]),
          Padding(
            padding: const EdgeInsets.all(5),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: Text(comment ?? ""),
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
                        style: TextButton.styleFrom(
                            padding: const EdgeInsets.all(1)),
                        onPressed: () async {
                          final url = await FirebaseStorage.instance
                              .ref()
                              .child("assignments/${widget.id}/$studId/$file")
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

  String success = '';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text(
          widget.title,
        )),
        body: widget.type == 'Student'
            ? SingleChildScrollView(
                child: Form(
                key: inpFormKey,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: <Widget>[
                      Container(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.desc,
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                              fontSize: 16, fontStyle: FontStyle.italic),
                        ),
                      ),

                      const SizedBox(height: 16.0),

                      //due date
                      Container(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Due ${widget.deadline}",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),

                      const SizedBox(height: 16.0),

                      SizedBox(
                        height: 200,
                        child: Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10.0)),
                            ),
                            child: SingleChildScrollView(
                              child: TextFormField(
                                controller: commentController,
                                onSaved: (value) {
                                  inpForm["inpComment"] = value;
                                  value = "";
                                },
                                decoration: const InputDecoration(
                                  labelText: "Add Comments",
                                ),
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),

                      //add attachments
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: MediaQuery.sizeOf(context).width -
                                MediaQuery.sizeOf(context).width * 0.50,
                            height: selectedFiles.isNotEmpty ? 100 : 50,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: selectedFiles.isNotEmpty
                                    ? ListView(
                                        children: [
                                          for (final file
                                              in inpForm["inpAttachList"])
                                            ListTile(title: Text(file)),
                                        ],
                                      )
                                    : const Center(
                                        child: Text("Add Attatchments"),
                                      ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 8.0),

                          //to select a file
                          ElevatedButton(
                            onPressed: pickFiles,
                            child: const Text("Select Files"),
                          ),
                        ],
                      ),
                      Visibility(
                          visible: hasError,
                          child: Text(
                            error,
                            style: TextStyle(color: Colors.redAccent[700]),
                          )),
                      const SizedBox(height: 30.0),
                      ElevatedButton(
                        onPressed: () {
                          if (commentController.text == "" &&
                              selectedFiles.isEmpty) {
                            setState(() {
                              error = "cannot send an empty assignment";
                              hasError = true;
                            });
                          } else {
                            inpFormKey.currentState!.save();
                            dbref
                                .child(
                                    'subject_acts/${widget.id}/responses/${userRef.currentUser!.uid}/')
                                .set(inpForm);
                            uploadFiles(widget.id);
                            setState(() {
                              hasSubmitted = true;
                              success = "Submission success";
                            });
                          }
                        },
                        child: const Text(
                          "Submit Assignment",
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Visibility(
                          visible: hasSubmitted,
                          child: Text(
                            success,
                            style: const TextStyle(color: Colors.green),
                          )),
                    ],
                  ),
                ),
              ))
            : respoData.keys.length > 0 || respoData != null
                ? ListView.builder(
                    itemCount: respoData.keys.length,
                    itemBuilder: (context, index) {
                      final student = respoData.keys.elementAt(index);
                      final content = respoData[student];
                      return response(context,
                          date: content["inpStamp"],
                          comment: content["inpComment"],
                          list: content["inpAttachList"],
                          studId: student);
                    })
                : const Center(
                    child: Text('No one Has Attended yet'),
                  ));
  }
}
