import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCodeScreen extends StatelessWidget {
  final String id;

  const QrCodeScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('QR Code'),
        ),
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                "Scan this for Session Attendance",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
              ),
            ),
            QrImageView(
              data: id,
              version: QrVersions.auto,
              size: 200.0,
            ),
          ]),
        ));
  }
}
