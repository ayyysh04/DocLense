import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

Future<dynamic> renameOnPressed(
    {@required VoidCallback setState,
    @required BuildContext context,
    @required Box<dynamic> pdfsBox,
    @required int index}) {
  TextEditingController pdfName;
  return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        pdfName = TextEditingController();
        return AlertDialog(
          title: const Text(
            "Rename",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: SizedBox(
            height: MediaQuery.of(context).size.height / 5,
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              TextField(
                controller: pdfName,
                decoration: InputDecoration(
                  labelText: 'Rename',
                  labelStyle: TextStyle(color: Colors.grey[500]),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    borderSide: BorderSide(width: 2, color: Colors.grey[500]),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    borderSide: BorderSide(width: 2, color: Colors.grey[500]),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.01),
              ElevatedButton(
                onPressed: () async {
                  final List<dynamic> starred =
                      Hive.box('starred').getAt(0) as List<dynamic>;
                  final List<dynamic> finalStarred = [];
                  for (int i = 0; i < starred.length; i++) {
                    finalStarred.add(starred[i][0]);
                  }

                  print("PDFS : ${Hive.box('pdfs').getAt(0)}");
                  final File sourceFile =
                      File(pdfsBox.getAt(0)[index][0] as String);

                  if (finalStarred.contains(pdfsBox.getAt(0)[index][0])) {
                    print('yes');
                    for (int i = 0; i < finalStarred.length; i++) {
                      if (Hive.box('starred').getAt(0)[i][0] ==
                          sourceFile.path) {
                        print('yes');
                        final List<String> path =
                            (Hive.box('starred').getAt(0)[i][0] as String)
                                .split('/');
                        path.last = "${pdfName.text}.pdf";
                        Hive.box('starred').getAt(0)[i][0] = path.join('/');
                        final List<dynamic> editedList =
                            Hive.box('starred').getAt(0) as List<dynamic>;
                        Hive.box('starred').putAt(0, editedList);
                        break;
                      }
                    }
                  }
                  final List<String> path =
                      pdfsBox.getAt(0)[index][0].split('/') as List<String>;
                  path.last = "${pdfName.text}.pdf";
                  pdfsBox.getAt(0)[index][0] = path.join('/');
                  setState();
                  sourceFile.renameSync(pdfsBox.getAt(0)[index][0] as String);
                  print("PDFS : ${Hive.box('pdfs').getAt(0)}");
                  final List<dynamic> editedList =
                      pdfsBox.getAt(0) as List<dynamic>;
                  pdfsBox.putAt(0, editedList);
                  Navigator.pop(dialogContext);
                },
                child: const Text("Save"),
              ),
            ]),
          ),
        );
      });
}
