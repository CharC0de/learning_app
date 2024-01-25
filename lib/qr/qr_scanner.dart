import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:learning_app/utilities/server_util.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'res_screen.dart';
import 'attendance/attendance.dart';

class QRCodeScannerPage extends StatefulWidget {
  const QRCodeScannerPage({super.key, required this.details, required this.id});
  final dynamic details;
  final String id;

  @override
  State<QRCodeScannerPage> createState() => _QRCodeScannerPageState();
}

String sessionId = '';
dynamic sessionDet = {};

class _QRCodeScannerPageState extends State<QRCodeScannerPage> {
  var existSession = false;
  void initialSession() {
    dbRef
        .child('sessions/')
        .orderByChild('subjectId')
        .equalTo(widget.id)
        .onValue
        .listen((event) {
      setState(() {
        sessionDet = event.snapshot.value;
      });
      debugPrint('sessionDet is null ${sessionDet != null}');
    });
  }

  void createNewSession() {
    setState(() {
      sessionId = dbRef.push().key!;
      existSession = true;
    });

    final sessionVal = {
      "sessionDate": Timestamp.now().toString(),
      'active': true,
      'teacherId': userRef.currentUser!.uid,
      'subjectId': widget.id,
    };

    dbRef.child('sessions/$sessionId/').set(sessionVal);
  }

  String admission = "Student does not exist";
  Future<void> queryuser(scannedData) async {
    var data = await dbRef.child('users/$scannedData').get();
    if (data.value != null) {
      var users = (data.value as Map).cast<String, dynamic>();
      debugPrint('User DETECTED: ${users.toString()}');
      if (context.mounted) {
        if (users["type"] == 'Student') {
          setState(() {
            admission = 'Admit ${users["uName"]}?';
          });
          // Additional user data can be accessed here if needed
        }
      }
    }
  }

  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  late QRViewController controller;
  StreamSubscription? sessStream;

  final dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        "https://learning-app-c8a25-default-rtdb.asia-southeast1.firebasedatabase.app/",
  ).ref();

  @override
  void initState() {
    initSession();
    super.initState();
    debugPrint(widget.id);
  }

  String sessionId = '';
  bool isProcessing = false;

  void initSession() {
    sessStream = dbRef
        .child('sessions/')
        .orderByChild('subjectId')
        .equalTo(widget.id)
        .onValue
        .listen((event) {
      if (context.mounted) {
        debugPrint(widget.id);
        if (event.snapshot.value != null) {
          final sessions = (event.snapshot.value as Map<dynamic, dynamic>)
              .cast<String, dynamic>();
          debugPrint('trIgger1');

          final filteredSessions = sessions.entries
              .where((entry) => entry.value['active'] == true)
              .toList();

          debugPrint(
              "*****************************${filteredSessions.toString()}");
          if (filteredSessions.isNotEmpty) {
            setState(() {
              sessionId = filteredSessions.first.key;
              existSession = true;
            });
            debugPrint(sessionId);
            debugPrint(existSession.toString());
          } else if (filteredSessions.isEmpty) {
            setState(() {
              debugPrint('trIgger6');
              existSession = false;
            });
          }
        } else {
          debugPrint('Trgger3');
          setState(() {
            existSession = false;
          });
        }
      }
    });
  }

  void resumeCamera() {
    if (Platform.isAndroid) {
      controller.pauseCamera();
    }
    controller.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 200.0
        : 350.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Theme.of(context).colorScheme.primary,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: scanArea,
              ),
            ),
          ),
        ],
      ),
      persistentFooterAlignment: AlignmentDirectional.center,
      persistentFooterButtons: existSession
          ? [
              FilledButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => AttendancePage(sessId: sessionId)));
                },
                child: const Text('Show Attendance'),
              ),
            ]
          : null,
    );
  }

  void _onQRViewCreated(QRViewController controller) async {
    setState(() {
      this.controller = controller;
    });

    try {
      resumeCamera();
    } catch (error) {
      debugPrint(error.toString());
    }

    controller.scannedDataStream.listen((scanData) async {
      if (isProcessing) {
        return;
      }

      // Set processing flag to true to prevent multiple executions
      isProcessing = true;

      setState(() {
        result = scanData;
      });

      if (scanData.code != null) {
        await controller.pauseCamera();
        await queryuser(scanData.code);

        /*Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              scannedData: scanData.code!,
              id: widget.id,
              details: widget.details,
            ),
          ),
        );*/
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'Attendance Success',
                    style: TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    admission,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: admission == "Student does not exist"
                  ? null
                  : [
                      FilledButton(
                        onPressed: () {
                          debugPrint(sessionDet.toString());
                          // Your 'Yes' button logic here
                          if (existSession) {
                            debugPrint(sessionId);
                            debugPrint(scanData.code);
                            dbRef
                                .child(
                                    'sessions/$sessionId/students/${scanData.code}')
                                .set(true);
                          } else {
                            createNewSession();
                            dbRef
                                .child(
                                    'sessions/$sessionId/students/${scanData.code}')
                                .set(true);
                          }
                          debugPrint(
                              'sessions/$sessionId/students/${scanData.code}');

                          if (context.mounted) {
                            setState(() {
                              admission = '';
                            });

                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text("Yes", textAlign: TextAlign.center),
                      ),
                      FilledButton(
                        onPressed: () {
                          // Your 'No' button logic here
                          Navigator.of(context).pop();
                        },
                        child: const Text("No", textAlign: TextAlign.center),
                      ),
                    ],
            ),
          );
        }
      }
      resumeCamera();
      debugPrint('Scanned QR Code: ${scanData.code}');

      isProcessing = false;
    });
  }

  @override
  void deactivate() {
    if (sessStream != null) {
      sessStream!.cancel();
    }

    super.deactivate();
  }
}
