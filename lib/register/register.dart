import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../utilities/util.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'alert_dialog_register.dart';

class UserRegistration extends StatefulWidget {
  const UserRegistration({super.key, required this.type});
  final String? type;
  @override
  State<UserRegistration> createState() => _UserRegistrationState();
}

class _UserRegistrationState extends State<UserRegistration> {
  @override
  void initState() {
    setState(() {
      userForm["type"] = widget.type;
    });
    super.initState();
  }

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  bool isUnameUnique = true;

  Future<void> validateUname(username) async {
    try {
      DataSnapshot users = await dbRef.child('/users/').get();
      var data = (users.value as Map<dynamic, dynamic>).cast<String, dynamic>();

      var res = Map.fromEntries(
          data.entries.where((val) => val.value['uName'] == username));
      debugPrint(res.toString());
      setState(() {
        isUnameUnique = res.isEmpty;
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final storageRef = FirebaseStorage.instance;
  StreamSubscription? userStream;
  final storeRef = FirebaseStorage.instance.ref();
  final dbRef = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL:
              "https://learning-app-c8a25-default-rtdb.asia-southeast1.firebasedatabase.app/")
      .ref();
  final userRef = FirebaseAuth.instance;

  String success = "";

  File? _image;

  Map<String, dynamic> userForm = {
    "uName": "",
    "email": "",
    "fName": "",
    "lName": "",
    "type": "",
    "contact": "",
    "password": "",
  };

  InputDecoration passDecoration(String identifier, bool showPass) =>
      InputDecoration(
        hintText: identifier,
        labelText: identifier,
        prefixIcon: Icon(
          Icons.lock,
          color: Theme.of(context).colorScheme.primary,
        ),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              identifier == 'Confirm Password'
                  ? _obscureConfirmPassword = !_obscureConfirmPassword
                  : _obscurePassword = !_obscurePassword;
            });
            debugPrint(showPass.toString());
          },
          icon: Icon(
            showPass ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
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
      );

  Container buttonStyle(Widget widget) => Container(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 18),
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 18),
          child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 50,
              child: widget)));

  Future<void> _takePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        userForm["pfp"] = pickedFile.path.split('/').last;
        debugPrint(userForm["pfp"]);
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        userForm["pfp"] = pickedFile.path.split('/').last;
        debugPrint(userForm["pfp"]);
      });
    }
  }

  Future<void> uploadImage(String folder, File? file, String fileName) async {
    final storage = FirebaseStorage.instance;
    final Reference storageRef = storage.ref().child("$folder/$fileName");

    try {
      await storageRef.putFile(file!);
      debugPrint('File uploaded to Firestore in folder: $folder');
    } catch (e) {
      debugPrint('Error uploading file: $e');
    }
  }

  UserCredential? userCredential;
  Future<bool> registerUser(String email, String password) async {
    try {
      userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint(userCredential!.user!.uid);
      return true;
    } catch (e) {
      debugPrint(e.toString());
      if (e is FirebaseAuthException) {
        if (context.mounted) {
          Navigator.of(context).pop();
          showDialog(
              context: context,
              builder: (context) => e.code == 'email-already-in-use'
                  ? const AlertDialog(
                      title: Text('Email is Already in Use'),
                      content: Text(
                          'Email address is already in use. Please choose another one.'),
                    )
                  : const AlertDialog(
                      title: Text('Error Has Occured'),
                      content: Text('Please call the Administratot'),
                    ));
        }
        return false;
      }
    }
    return true;
  }

  Future<void> saveUserData(String user, Map<String, dynamic> userData) async {
    try {
      debugPrint(user);
      final fireBaseApp = Firebase.app();
      final databaseReference = FirebaseDatabase.instanceFor(
              app: fireBaseApp,
              databaseURL:
                  "https://learning-app-c8a25-default-rtdb.asia-southeast1.firebasedatabase.app/")
          .ref();
      await databaseReference.child("users").child(user).set(userData);
      debugPrint("Data saved successfully");
    } catch (e) {
      debugPrint("Error while saving data: $e");
      // You can handle the error here, e.g., show an error message to the user.
    }
  }

  Future<void> registerUserWithProfile(Map<String, dynamic> userForm) async {
    final email = userForm["email"];
    final password = userForm["password"];

    final userData = {
      "uName": userForm["uName"],
      "fName": userForm["fName"],
      "lName": userForm["lName"],
      "contact": userForm["contact"],
      "pfp": userForm["pfp"],
      "type": userForm["type"],
    };

    if (await registerUser(email, password)) {
      try {
        saveUserData(userCredential!.user!.uid, userData);
        if (userForm["pfp"] != null) {
          debugPrint(userForm["pfp"] + "wews");
          uploadImage(userCredential!.user!.uid, _image, userForm["pfp"]);
        }
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        debugPrint(e.toString());
      } finally {
        setState(() {
          success = 'Register Success';
          _formKey.currentState!.reset();
          _passwordController.clear();
          _confirmPasswordController.clear();
          _emailController.clear();
          _usernameController.clear();
          debugPrint(userForm.toString());
        });
        if (context.mounted) {
          AlertDialogRegister.showSuccessDialog(
            context,
            'Registered Successfully',
            'You have successfully registered.',
          );
        }
      }
    }
  }

  AlertDialog choosePfpPopup(BuildContext context) => AlertDialog(
        actionsAlignment: MainAxisAlignment.center,
        actionsOverflowAlignment: OverflowBarAlignment.center,
        title: Expanded(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              const Text("Upload Picture"),
              GestureDetector(
                  onTap: () => Navigator.pop(context, 'exit'),
                  child: Icon(Icons.cancel_rounded,
                      color: Theme.of(context).colorScheme.primary))
            ])),
        content: const Text("How would you like to take your picture"),
        actions: [
          FilledButton(
            onPressed: () {
              _takePicture();
              Navigator.pop(context, 'exit');
            },
            child: const Text('Take Picture'),
          ),
          FilledButton(
            onPressed: () {
              _pickImage();
              Navigator.pop(context, 'exit');
            },
            child: const Text('Choose Picture'),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF006497),
      appBar: AppBar(
        backgroundColor: const Color(0xFF006497),
        title: Text(
          '${widget.type} Registration',
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFAEC5D1),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  if (_image != null)
                    TextButton(
                        style: ButtonStyle(
                            shape: MaterialStateProperty.all(
                                const CircleBorder())),
                        onPressed: () {
                          setState(() {
                            _image = null;
                          });
                        },
                        child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: CircleAvatar(
                              radius: 100,
                              backgroundImage: FileImage(_image!, scale: 50),
                            )))
                  else
                    Icon(Icons.account_circle,
                        size: 100,
                        color: Theme.of(context).colorScheme.onSurface),
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Username',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            prefixIcon: const Icon(Icons.person),
                          ),
                          onSaved: (newValue) {
                            userForm["uName"] = newValue;
                            newValue = "";
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter a Username';
                            } else if (!isUsernameValidated(value)) {
                              return 'Invalid Username';
                            } else if (value.length < 4) {
                              return 'Username should be at least 4 characters long';
                            } else if (!isUnameUnique) {
                              return 'Username is taken';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'First Name',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            prefixIcon: null, // No prefix icon for this field
                          ),
                          onSaved: (newValue) {
                            userForm["fName"] = newValue;
                            newValue = "";
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter your First Name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Last Name',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            prefixIcon: null, // No prefix icon for this field
                          ),
                          onSaved: (newValue) {
                            userForm["lName"] = newValue;
                            newValue = "";
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter your Last Name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            prefixIcon: const Icon(Icons.email),
                          ),
                          onSaved: (newValue) {
                            userForm["email"] = newValue;
                            newValue = "";
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter an Email';
                            } else if (!isEmailValidated(value)) {
                              return 'Invalid Email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Contact Number',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            prefixIcon: const Icon(Icons.phone),
                          ),
                          onSaved: (newValue) {
                            userForm["contact"] = newValue;
                            newValue = "";
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter your Contact Number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Password',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          onSaved: (newValue) {
                            userForm["password"] = newValue;
                            newValue = "";
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter a password';
                            } else if (value.length < 6) {
                              return 'Password should be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Confirm your password';
                            } else if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: Column(children: [
                      buttonStyle(FilledButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                              const Color(0xFF006497)),
                        ),
                        onPressed: () => showDialog<String>(
                            context: context,
                            builder: (context) => choosePfpPopup(context)),
                        child: const Text(
                          'Take a Profile Photo',
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                      )),
                      buttonStyle(FilledButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                              const Color(0xFF006497)),
                        ),
                        onPressed: () async {
                          await validateUname(_usernameController.text);
                          if (_formKey.currentState!.validate()) {
                            if (context.mounted) {
                              showDialog(
                                  context: context,
                                  builder: (context) => const AlertDialog(
                                        title: Center(
                                            child: CircularProgressIndicator()),
                                      ));
                            }

                            _formKey.currentState!.save();
                            registerUserWithProfile(userForm);
                            debugPrint(userForm.toString());
                          }
                        },
                        child: const Text(
                          'Register',
                          style: TextStyle(color: Colors.white, fontSize: 22),
                        ),
                      )),
                      Text(
                        success,
                        style: const TextStyle(
                            color: Colors.green, fontWeight: FontWeight.w400),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
