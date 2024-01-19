// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:juanapp/components/my_textfield.dart';
import 'package:juanapp/components/my_button.dart';
import 'package:juanapp/services/auth/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  bool _isLoading = false;
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      // Fetch user profile from Firestore
      var user = AuthService().getCurrentUser();
      if (user != null) {
        var userData = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();
        if (userData.exists) {
          setState(() {
            _email = userData.data()!['email'];
            _usernameController.text = userData.data()!['username'] ?? _email;
            _passwordController.text = userData.data()!['password'] ?? '';
            _locationController.text = userData.data()!['location'] ?? '';
            _genderController.text = userData.data()!['gender'] ?? '';
            _ageController.text = userData.data()!['age'] ?? '';
            _fullnameController.text = userData.data()!['fullname'] ?? '';
          });
        }
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(e.toString()),
        ),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      var user = AuthService().getCurrentUser();
      if (user != null) {
        // Update user profile in Firestore
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .update({
          'location': _locationController.text,
          'gender': _genderController.text,
          'age': _ageController.text,
          'fullname': _fullnameController.text,
          'username': _usernameController.text,
          // Don't store password in Firestore; handle it separately with Firebase Auth
        });
        // Optionally, handle password update with Firebase Authentication here
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(e.toString()),
        ),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Email: $_email'), // Non-editable
            MyTextField(
              hintText: 'Password',
              obscureText: true,
              controller: _passwordController,
            ),
            MyTextField(
              hintText: 'Location',
              obscureText: false,
              controller: _locationController,
            ),
            MyTextField(
              hintText: 'Gender',
              obscureText: false,
              controller: _genderController,
            ),
            MyTextField(
              hintText: 'Age',
              obscureText: false,
              controller: _ageController,
            ),
            MyButton(
              text: 'Update Profile',
              onTap: _updateProfile,
            ),

            const SizedBox(height: 20),

            MyButton(
              text: 'Change Password',
              onTap: _changePassword,
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _verifyCurrentPassword(String password) async {
    var user = AuthService().getCurrentUser();
    var authCredentials = EmailAuthProvider.credential(
      email: user!.email!,
      password: password,
    );
    try {
      var authResult = await user.reauthenticateWithCredential(authCredentials);
      return authResult.user != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> _updatePassword(String newPassword) async {
    var user = AuthService().getCurrentUser();
    await user!.updatePassword(newPassword).then((_) {
      // Successfully updated password
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password successfully updated!')),
      );
    }).catchError((error) {
      // Error occurred
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update password: $error')),
      );
    });
  }

  Future<void> _changePassword() async {
    // Prompt the user to enter their current password
    String currentPassword =
        ''; // This should be obtained from a dialog with a TextField

    // Display a dialog to get the current password from the user
    String? enteredPassword = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify Current Password'),
        content: TextField(
          onChanged: (value) => currentPassword = value,
          obscureText: true,
          decoration: const InputDecoration(hintText: "Enter current password"),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Submit'),
            onPressed: () => Navigator.of(context).pop(currentPassword),
          ),
        ],
      ),
    );

    if (enteredPassword != null && enteredPassword.isNotEmpty) {
      bool isPasswordCorrect = await _verifyCurrentPassword(enteredPassword);
      if (isPasswordCorrect) {
        String newPassword =
            _passwordController.text; // New password from user input
        await _updatePassword(newPassword);
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Password has been changed successfully')),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect current password')),
        );
      }
    }
  }
}
