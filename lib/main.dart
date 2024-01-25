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
      theme: ThemeData(
          bottomAppBarTheme: BottomAppBarTheme(
              color: Colors.blue[700], surfaceTintColor: Colors.white),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
              shape: CircleBorder(),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white),
          tabBarTheme: const TabBarTheme(
              unselectedLabelColor: Colors.black, labelColor: Colors.white),
          dividerTheme: const DividerThemeData(
            color: Colors.transparent,
          ),
          appBarTheme: AppBarTheme(
              centerTitle: true,
              color: Colors.blue[700],
              foregroundColor: Colors.white),
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
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
            Navigator.of(context).pop();
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => DashBoard(type: userData['type'])));
            debugPrint('$userData');
          } else {
            Navigator.of(context).pop();
            debugPrint("User not found");
          }
        }, onError: (error) {
          Navigator.of(context).pop();
          debugPrint('Error fetching user data: $error');
        });
        debugPrint('$type is the important');
      } else {
        Navigator.of(context).pop();
        setState(() {
          error = "Invalid Credentials";
        });
      }
    } catch (e) {
      Navigator.of(context).pop();
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
        backgroundColor: const Color(0xFF004B73),
        actionsAlignment: MainAxisAlignment.center,
        title: Expanded(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              const Text(
                "",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              GestureDetector(
                  onTap: () => Navigator.pop(context, 'exit'),
                  child: Icon(Icons.cancel_rounded,
                      color: Theme.of(context).colorScheme.primary))
            ])),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Image.asset(
                'images/Logo.png',
                fit: BoxFit.cover,
                width: 100,
                height: 100,
              ),
            ),
            const Text(
              "Select an Account Type",
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const Text(
              "Choose an Account Type",
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        contentPadding: const EdgeInsets.all(20),
        actions: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFAEC5D1),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        const Color(0xFF004B73)),
                  ),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const UserRegistration(type: "Student")));
                  },
                  child: const Text('Sign Up as Student'),
                ),
                FilledButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        const Color(0xFF004B73)),
                  ),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const UserRegistration(type: "Teacher")));
                  },
                  child: const Text('Sign Up as Teacher'),
                ),
              ],
            ),
          )
        ],
      );

  ButtonStyle loginButtonStyle =
      FilledButton.styleFrom(minimumSize: const Size(400, 50));

  final loginKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF004B73),
      body: Center(
          child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              child: Image.asset(
                'images/Logo.png',
                fit: BoxFit.cover,
                width: 100,
                height: 100,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            const Text(
              "Welcome Back!",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
                color: Colors.white,
              ),
            ),
            const Text(
              "Login to your EduQ account.",
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'Roboto',
                color: Colors.white,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFAEC5D1),
                borderRadius: BorderRadius.circular(10.0),
              ),
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.only(top: 10),
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
                                  return 'Enter email';
                                }
                                return null;
                              },
                              keyboardType: TextInputType.emailAddress,
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
                            keyboardType: TextInputType.visiblePassword,
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
                              alignment: Alignment.center,
                              child: TextButton(
                                  onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const ChangePass())),
                                  child: const Text("Forgot Password?"))),
                          butContainer(FilledButton(
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        const Color(0xFF006497)),
                              ),
                              onPressed: () {
                                if (loginKey.currentState!.validate()) {
                                  showDialog(
                                      context: context,
                                      builder: (context) => const AlertDialog(
                                            title: Center(
                                                child:
                                                    CircularProgressIndicator()),
                                          ));
                                  loginKey.currentState!.save();

                                  loginUser(credentials['email'],
                                      credentials["password"], context);
                                }
                                debugPrint(credentials.toString());
                              },
                              child: const Text("Login")))
                        ],
                      )),
                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed: () => showDialog<String>(
                        context: context,
                        builder: (context) => chooseRegPopup(context),
                      ),
                      child: RichText(
                        text: const TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.normal,
                              color: Colors.black),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'Sign Up',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      )),
    );
  }
}
