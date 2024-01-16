import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../main.dart';
import '../../teacher/sessions.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});
  @override
  State<UserProfile> createState() => _UserProfile();
}

class _UserProfile extends State<UserProfile> {
  @override
  initState() {
    getUserData();

    super.initState();
  }

  var sessData = {};
  final Map<String, dynamic> userData = {
    "uName": "",
    "fName": "",
    "lName": "",
    "contact": "",
    "pfp": "",
    "type": "",
  };
  StreamSubscription? userStream;
  final storeRef = FirebaseStorage.instance.ref();
  final dbRef = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL:
              "https://learning-app-c8a25-default-rtdb.asia-southeast1.firebasedatabase.app/")
      .ref();
  final userRef = FirebaseAuth.instance;
  Image? pfp;
  getUserData() {
    userStream = dbRef
        .child('users/${userRef.currentUser!.uid}/')
        .onValue
        .listen((event) {
      if (event.snapshot.value != null) {
        final resData = (event.snapshot.value as Map<dynamic, dynamic>)
            .cast<String, dynamic>();
        setState(() {
          userData["uName"] = resData["uName"];
          userData["fName"] = resData["fName"];
          userData["lName"] = resData["lName"];
          userData["contact"] = resData["contact"];
          userData["pfp"] = resData["pfp"];
          userData["type"] = resData["type"];
        });
      }
    });
  }

  Future<Widget> getAll() async {
    try {
      debugPrint(userRef.currentUser!.uid);
      final ref = FirebaseStorage.instance
          .ref()
          .child("${userRef.currentUser!.uid}/${userData["pfp"]}");
      final url = await ref.getDownloadURL();
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 100,
                backgroundImage: NetworkImage(url),
              ),
              const SizedBox(height: 16),
              Text(
                userData["uName"]!,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                userData["type"]!,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Container(
                  constraints: const BoxConstraints(
                      maxWidth: 400), // Set a maximum width
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProfileField(
                            label: 'Username: ', value: userData["uName"]!),
                        ProfileField(
                            label: 'Email: ',
                            value: userRef.currentUser!.email!),
                        ProfileField(
                            label: 'First name: ', value: userData["fName"]!),
                        ProfileField(
                            label: 'Last name: ', value: userData["lName"]!),
                        ProfileField(
                            label: 'Contact #: ', value: userData["contact"]!),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error loading image from Firebase Storage: $e');
      debugPrint('>>${userRef.currentUser!.uid}/${userData["pfp"]}');
      // Handle the error or return a placeholder image.
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle, size: 100, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                userData["uName"]!,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                userData["type"]!,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Container(
                  constraints: const BoxConstraints(
                      maxWidth: 400), // Set a maximum width
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProfileField(
                            label: 'Username: ', value: userData["uName"]!),
                        ProfileField(
                            label: 'Email: ',
                            value: userRef.currentUser!.email!),
                        ProfileField(
                            label: 'First name: ', value: userData["fName"]!),
                        ProfileField(
                            label: 'Last name: ', value: userData["lName"]!),
                        ProfileField(
                            label: 'Contact #: ', value: userData["contact"]!),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ); // You can use a placeholder image.
    }
  }

  Container iconContainer(Widget child) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          GestureDetector(
            onTap: () {
              FirebaseAuth.instance.signOut();
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (context) => const Login()));
            },
            child: iconContainer(const Icon(Icons.logout_outlined)),
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
            child: FutureBuilder<Widget>(
          future: getAll(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator(); // Display a loading indicator while fetching the image.
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              return snapshot.data ?? const Text('Image not found');
            }
          },
        )),
      ),
      persistentFooterAlignment: AlignmentDirectional.center,
      persistentFooterButtons: [
        FilledButton(
          onPressed: () {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SessionData()));
          },
          child: const Text('Sessions'),
        )
      ],
    );
  }

  @override
  void deactivate() {
    userStream!.cancel();
    super.deactivate();
  }
}

class ProfileField extends StatelessWidget {
  final String label;
  final String value;

  const ProfileField({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ), // Adjust the value according to your preference
      ],
    );
  }
}
