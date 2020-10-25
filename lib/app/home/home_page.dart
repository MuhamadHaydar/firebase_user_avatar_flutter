import 'dart:async';
import 'dart:io';

import 'package:firebase_user_avatar_flutter/app/home/about_page.dart';
import 'package:firebase_user_avatar_flutter/common_widgets/avatar.dart';
import 'package:firebase_user_avatar_flutter/models/avatar_reference.dart';
import 'package:firebase_user_avatar_flutter/services/firebase_auth_service.dart';
import 'package:firebase_user_avatar_flutter/services/firebase_storage_service.dart';
import 'package:firebase_user_avatar_flutter/services/firestore_service.dart';
import 'package:firebase_user_avatar_flutter/services/image_picker_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  Future<void> _signOut(BuildContext context) async {
    try {
      final authService = Provider.of<FirebaseAuthService>(context);
      authService.signOut();
    } catch (e) {
      print(e);
    }
  }

  Future<void> _onAbout(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AboutPage(),
      ),
    );
  }

  Future<void> _chooseAvatar(BuildContext context) async {
    try {
      // Get the reference of image picker service.
      final imagePicker = Provider.of<ImagePickerService>(context);
      // Get the reference of storage service
      final firebaseStorageService =
          Provider.of<FirebaseStorageService>(context);
      // Get the reference of the user.
      final user = Provider.of<User>(context);
      // Get the reference of the Firestore.
      final firestore = Provider.of<FirestoreService>(context);
      // 1. Get image from picker
      File imageFile = await imagePicker.pickImage(source: ImageSource.gallery);
      if (imageFile != null) {
        // 2. Upload to storage
        String url = await firebaseStorageService.uploadAvatar(
            uid: user.uid, file: imageFile);
        // 3. Save url to Firestore
        await firestore.setAvatarReference(
          uid: user.uid,
          avatarReference: AvatarReference(url),
        );

        await imageFile.delete();
      }
      // 4. (optional) delete local file as no longer needed}
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        leading: IconButton(
          icon: Icon(Icons.help),
          onPressed: () => _onAbout(context),
        ),
        actions: <Widget>[
          FlatButton(
            child: Text(
              'Logout',
              style: TextStyle(
                fontSize: 18.0,
                color: Colors.white,
              ),
            ),
            onPressed: () => _signOut(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(130.0),
          child: Column(
            children: <Widget>[
              _buildUserInfo(context: context),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo({BuildContext context}) {
    // TODO: Download and show avatar from Firebase storage
    final firestoreService = Provider.of<FirestoreService>(
        context, listen: false);
    final user = Provider.of<User>(context);
    return StreamBuilder(
        stream: firestoreService.avatarReferenceStream(uid: user.uid),
        builder: (context, snapshot) {
          final avatarReference = snapshot.data;
          return Avatar(
            photoUrl: avatarReference?.downloadUrl,
            radius: 50,
            borderColor: Colors.black54,
            borderWidth: 2.0,
            onPressed: () => _chooseAvatar(context),
          );
        }
    );
  }
}
