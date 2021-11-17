import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

Future<void> favOnPressed({
  @required VoidCallback setState,
  @required BuildContext context,
  @required Box<dynamic> pdfsBox,
  @required int index,
}) async {
  print(isStarred(pdfsBox, index));
  final File file = File(await pdfsBox.getAt(0)[index][0] as String);
  final path = file.path;
  final date = pdfsBox.getAt(0)[index][1];
  final imagePreview = pdfsBox.getAt(0)[index][2];

  final List<dynamic> files = Hive.box('starred').getAt(0) as List<dynamic>;

  final List<dynamic> starredDocs = [];

  for (int i = 0; i < files.length; i++) {
    starredDocs.add(files[i][0]);
  }
  if (starredDocs.contains(path)) {
    for (int i = 0; i < starredDocs.length; i++) {
      if (Hive.box('starred').getAt(0)[i][0] == path) {
        Hive.box('starred').getAt(0).removeAt(i);
        break;
      }
    }
    setState();
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from starred documents')));
    print('Already fav');
  } else {
    files.add([path, date, imagePreview]);
    Hive.box('starred').putAt(0, files);
    print("STARRED : ${Hive.box('starred').getAt(0)}");
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to starred documents!')));
  }
  setState();
}

bool isStarred(Box<dynamic> pdfsBox, int index) {
  final File file = File(pdfsBox.getAt(0)[index][0] as String);
  final path = file.path;

  final List<dynamic> files = Hive.box('starred').getAt(0) as List<dynamic>;
  final List<dynamic> starredDocs = [];
  for (int i = 0; i < files.length; i++) {
    starredDocs.add(files[i][0]);
  }
  if (starredDocs.contains(path)) {
    return true;
  } else {
    return false;
  }
}
