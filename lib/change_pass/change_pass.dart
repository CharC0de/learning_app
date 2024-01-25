import 'package:flutter/material.dart';
import '../utilities/util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';

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
            child: widget,
          ),
        ),
      );

  InputDecoration inpDecoration(String identifier, IconData? icon) =>
      InputDecoration(
        prefixIcon: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        hintText: identifier,
        labelText: identifier,
        contentPadding: EdgeInsets.zero, // Remove padding inside the TextField
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: Colors.transparent,
          ),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: Colors.transparent,
          ),
        ),
      );

  BoxDecoration emailDecoration() => BoxDecoration(
        shape: BoxShape.rectangle,
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(width: 3, color: const Color(0xFF004B73)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFF004B73),
        appBar: AppBar(
          backgroundColor: const Color(0xFF004B73),
          title: const Text("Forgot Password",
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: Form(
          key: _formKey,
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                      height: 20), // Add spacing between logo and text
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage("images/Logo.png"),
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                  const SizedBox(
                      height:
                          20), // Add spacing between text and email TextFormField
                  const Text(
                    "Change your Password",
                    style: TextStyle(
                      color: Colors.white, // Set text color to white
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 20), // Add more spacing
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16), // Add padding to the sides
                    child: Container(
                      width: 331,
                      height: 218,
                      decoration: ShapeDecoration(
                        color: const Color(0xFFAEC5D1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center, // Center the content
                        children: [
                          Container(
                            width: 300, // Adjusted the width
                            height: 51.57,
                            decoration: emailDecoration(),
                            child: TextFormField(
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
                            ),
                          ),
                          const SizedBox(
                              height:
                                  20), // Add spacing between email and button
                          buttonStyle(
                            Container(
                              width: 150.59,
                              height: 41.65,
                              decoration: ShapeDecoration(
                                color: const Color(0xFF006497),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                shadows: const [
                                  BoxShadow(
                                    color: Color(0x3F000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 4),
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: FilledButton(
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
                                                      const Login(),
                                                ),
                                              );
                                            },
                                            child: const Text(
                                              "Ok",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    showDialog<String>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text("Error"),
                                        content: const Text(
                                          "Email was not sent. Please check your internet connection and try again.",
                                        ),
                                        actions: [
                                          FilledButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: const Text(
                                              "Ok",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                },
                                child: const Text(
                                  "Send Email",
                                  style: TextStyle(fontSize: 22),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
