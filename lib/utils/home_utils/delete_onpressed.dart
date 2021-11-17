import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

Future<dynamic> deleteOnPressed(
    {@required VoidCallback setState,
    @required BuildContext context,
    @required Box<dynamic> pdfsBox,
    @required int index}) {
  return showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: Colors.blueGrey[800],
          title: const Text(
            "The PDF will be permanently deleted.\nDo you want to proceed?",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                    onTap: () {
                      final File sourceFile =
                          File(pdfsBox.getAt(0)[index][0] as String);
                      print(sourceFile.path);
                      sourceFile.delete();
                      final List<dynamic> starredFiles =
                          Hive.box('starred').getAt(0) as List<dynamic>;

                      pdfsBox.getAt(0).removeAt(index);
                      final List<dynamic> editedList =
                          pdfsBox.getAt(0) as List<dynamic>;
                      pdfsBox.putAt(0, editedList);
                      final List<dynamic> finalStarredFiles = [];
                      for (int i = 0; i < starredFiles.length; i++) {
                        finalStarredFiles.add(starredFiles[i][0]);
                      }
                      if (finalStarredFiles.contains(sourceFile.path)) {
                        print('yes');
                        for (int i = 0; i < finalStarredFiles.length; i++) {
                          if (Hive.box('starred').getAt(0)[i][0] ==
                              sourceFile.path) {
                            print('yes');
                            Hive.box('starred').getAt(0).removeAt(i);
                            final List<dynamic> editedList =
                                Hive.box('starred').getAt(0) as List<dynamic>;
                            Hive.box('starred').putAt(0, editedList);
                            break;
                          }
                        }
                      }
                      setState();
                      Navigator.of(ctx).pop();
                    },
                    child: const Text(
                      "Yes",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    )),
                const Padding(
                  padding: EdgeInsets.all(10),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(ctx).pop();
                  },
                  child: const Text(
                    "No",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      });
}
