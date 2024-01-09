import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'register/register.dart';
import 'change_pass/change_pass.dart';
import 'utilities/util.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'dashboard/dashboard.dart';

import 'package:firebase_auth/firebase_auth.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FlutterDownloader.initialize(
    debug: true, // Enable debugging to see logs (optional)
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(),
      home: const Login(),
    );
  }
}

class Login extends StatefulWidget {
  const Login({super.key});
  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  Map<String, dynamic> credentials = {
    "email": "",
    "password": "",
  };
  @override
  void initState() {
    FirebaseAuth.instance.signOut();
    super.initState();
  }

  String type = "";

  final dbRef = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL:
              "https://learning-app-c8a25-default-rtdb.asia-southeast1.firebasedatabase.app/")
      .ref();

  String error = "";
  bool hidePass = true;
  Future<void> loginUser(String email, String password, context) async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        debugPrint("login success");
        dbRef.child('users/${user.uid}').onValue.listen((event) {
          if (event.snapshot.value != null) {
            final userData = (event.snapshot.value as Map<dynamic, dynamic>)
                .cast<String, dynamic>();

            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => DashBoard(type: userData['type'])));
            debugPrint('$userData');
          } else {
            // No user found with the specified UID
            debugPrint("User not found");
          }
        }, onError: (error) {
          // Handle errors during data retrieval
          debugPrint('Error fetching user data: $error');
        });
        debugPrint('$type is the important');
      } else {
        setState(() {
          error = "Invalid Credentials";
        });
      }
    } catch (e) {
      debugPrint("Error while logging in: $e");
      setState(() {
        error = "Invalid Credentials";
      });
    }
  }

  Container butContainer(Widget widget) {
    return Container(
        margin: const EdgeInsets.all(5),
        child: SizedBox(
            width: MediaQuery.of(context).size.width / 2,
            height: 40,
            child: widget));
  }

  AlertDialog chooseRegPopup(BuildContext context) => AlertDialog(
        actionsAlignment: MainAxisAlignment.center,
        title: Expanded(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              const Text("Register"),
              GestureDetector(
                  onTap: () => Navigator.pop(context, 'exit'),
                  child: Icon(Icons.cancel_rounded,
                      color: Theme.of(context).colorScheme.primary))
            ])),
        content: const Text("Would you like to Register as"),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const UserRegistration(type: "Student")));
            },
            child: const Text('Student'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const UserRegistration(type: "Teacher")));
            },
            child: const Text('Teacher'),
          ),
        ],
      );

  ButtonStyle loginButtonStyle =
      FilledButton.styleFrom(minimumSize: const Size(400, 50));

  final loginKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              child: Image.asset(
                'images/Logo.png',
                fit: BoxFit.cover,
                width: 200,
                height: 200,
              ),
            ),
            Container(
              margin: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Form(
                      key: loginKey,
                      child: Column(
                        children: [
                          inpContainer(TextFormField(
                              onSaved: (value) {
                                credentials["email"] = value;
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter password';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                prefixIcon: Icon(
                                  Icons.email,
                                ),
                                hintText: "email",
                              ))),
                          inpContainer(TextFormField(
                            onSaved: (value) {
                              credentials["password"] = value;
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter password';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (hidePass) {
                                        hidePass = false;
                                      } else {
                                        hidePass = true;
                                      }
                                    });
                                  },
                                  child: Icon(
                                    hidePass
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  )),
                              hintText: "password",
                            ),
                            obscureText: hidePass,
                          )),
                          Text(
                            error,
                            style: const TextStyle(color: Colors.red),
                          ),
                          Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                  onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const ChangePass())),
                                  child: const Text("Forgot Password?"))),
                          butContainer(FilledButton(
                              style: loginButtonStyle,
                              onPressed: () {
                                if (loginKey.currentState!.validate()) {
                                  loginKey.currentState!.save();

                                  loginUser(credentials['email'],
                                      credentials["password"], context);
                                }
                                debugPrint(credentials.toString());
                              },
                              child: const Text("Login")))
                        ],
                      )),
                  butContainer(FilledButton(
                      style: loginButtonStyle,
                      onPressed: () => showDialog<String>(
                          context: context,
                          builder: (context) => chooseRegPopup(context)),
                      child: const Text("Register"))),
                ],
              ),
            )
          ],
        ),
      )),
    );
  }
}
