import 'dart:io';

import 'package:doclense/constants/route_constants.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';

moveToFolder(
    {@required VoidCallback setState,
    @required BuildContext context,
    @required Box<dynamic> pdfsBox,
    @required int index}) async {
  final status = await Permission.storage.status;
  if (!status.isGranted) {
    await Permission.storage.request();
  }
  final String oldPath = pdfsBox.getAt(0)[index][0] as String;
  String newPath;
  final String path = await ExtStorage.getExternalStorageDirectory();
  final Directory directory = Directory(path);
  Navigator.of(context).pushNamed(
    RouteConstants.folderPickerPage,
    arguments: {
      'rootDirectory': directory,
      'action': (BuildContext context, Directory folder) async {
        newPath =
            '${folder.path}/${(pdfsBox.getAt(0)[index][0] as String).split('/').last}';
        print(newPath);
        if (newPath != null) {
          final List<dynamic> starred =
              Hive.box('starred').getAt(0) as List<dynamic>;
          final List<dynamic> finalStarred = [];
          for (int i = 0; i < starred.length; i++) {
            finalStarred.add(starred[i][0]);
          }
          final File sourceFile = File(oldPath);
          if (finalStarred.contains(pdfsBox.getAt(0)[index][0])) {
            print('yes');
            for (int i = 0; i < finalStarred.length; i++) {
              if (Hive.box('starred').getAt(0)[i][0] == sourceFile.path) {
                print('yes');
                await sourceFile.copy(newPath);
                await sourceFile.delete();

                Hive.box('starred').getAt(0)[i][0] = newPath;
                pdfsBox.getAt(0)[index][0] = newPath;
                final List<dynamic> editedList =
                    Hive.box('starred').getAt(0) as List<dynamic>;
                Hive.box('starred').putAt(0, editedList);
                final List<dynamic> pdfEditedList =
                    pdfsBox.getAt(0) as List<dynamic>;
                pdfsBox.putAt(0, pdfEditedList);
                break;
              }
            }
          } else {
            print("Newpath: $newPath");
            await sourceFile.copy(newPath);
            await sourceFile.delete();
            setState();
            pdfsBox.getAt(0)[index][0] = newPath;
          }
        }
        Navigator.of(context).pop();
      },
    },
  );
}
