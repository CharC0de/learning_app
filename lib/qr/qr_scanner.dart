import 'dart:async';
import 'dart:io';

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

class _QRCodeScannerPageState extends State<QRCodeScannerPage> {
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
      if (event.snapshot.value != null) {
        final sessions = (event.snapshot.value as Map<dynamic, dynamic>)
            .cast<String, dynamic>();

        final filteredSessions = sessions.entries
            .where((entry) => entry.value['active'] == true)
            .toList();

        if (filteredSessions.isNotEmpty &&
            sessionId != filteredSessions.first.key) {
          setState(() {
            sessionId = filteredSessions.first.key;
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
      persistentFooterAlignment: AlignmentDirectional.topCenter,
      persistentFooterButtons: [
        FilledButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(const Color(0xFF006497)),
          ),
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => AttendancePage(sessId: sessionId)));
          },
          child: const Text('Show Attendance'),
        ),
        FilledButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(const Color(0xFF006497)),
          ),
            onPressed: () {
              dbRef.child('sessions/$sessionId/active/').set(false);
              Navigator.of(context).pop();
            },
            child: const Text('End Session'))
      ],
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

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              scannedData: scanData.code!,
              id: widget.id,
              details: widget.details,
            ),
          ),
        );
      }
      resumeCamera();
      debugPrint('Scanned QR Code: ${scanData.code}');

      // Reset processing flag after the processing is done
      isProcessing = false;
    });
  }

  @override
  void dispose() {
    if (sessStream != null) {
      sessStream!.cancel();
    }
    super.dispose();
  }
}
