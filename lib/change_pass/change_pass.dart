import 'package:flutter/material.dart';
import '../utilities/util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import "../main.dart";

class ChangePass extends StatefulWidget {
  const ChangePass({super.key});
  @override
  State<ChangePass> createState() => _ChangePassState();
}

class _ChangePassState extends State<ChangePass> {
  final _formKey = GlobalKey<FormState>();
  final bool showPass = false;
  String? email;
  bool success = true;

  void resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      debugPrint('Password reset email sent');
      setState(() {
        success = true;
      });
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      setState(() {
        success = false;
      });
    }
  }

  Container buttonStyle(Widget widget) => Container(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 18),
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 18),
          child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 50,
              child: widget)));

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
        title: const Text("Change Password"),
      ),
      body: Center(
        child: SingleChildScrollView(
            child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    inpContainer(TextFormField(
                      decoration: inpDecoration("Email", Icons.email),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter your email";
                        } else if (!isEmailValidated(value)) {
                          return "Invalid Email";
                        }
                        return null;
                      },
                      onSaved: (value) {
                        email = value;
                      },
                      keyboardType: TextInputType.emailAddress,
                    )),
                    buttonStyle(FilledButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                          }
                          resetPassword(email!);
                          if (success) {
                            showDialog<String>(
                                barrierDismissible: false,
                                context: context,
                                builder: (context) => AlertDialog(
                                      title: const Text("Email Sent"),
                                      content: Text(
                                        "Password Change email has been Sent to $email",
                                      ),
                                      actions: [
                                        FilledButton(
                                            onPressed: () {
                                              Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          const Login()));
                                            },
                                            child: const Text(
                                              "Ok",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            ))
                                      ],
                                    ));
                          } else {
                            showDialog<String>(
                                context: context,
                                builder: (context) => AlertDialog(
                                      title: const Text("Error"),
                                      content: const Text(
                                          "Email was not sent please check your internet connection and try again."),
                                      actions: [
                                        FilledButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: const Text(
                                              "Ok",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            )),
                                      ],
                                    ));
                          }
                        },
                        child: const Text(
                          "Send Email",
                          style: TextStyle(fontSize: 22),
                        )))
                  ],
                ))),
      ),
    );
  }
}
