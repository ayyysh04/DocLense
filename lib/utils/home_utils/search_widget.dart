import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:open_file/open_file.dart';

class SearchListView extends StatelessWidget {
  String query;
  SearchListView({
    Key key,
    @required this.query,
  }) : super(key: key);

  List<dynamic> files = Hive.box('pdfs').getAt(0) as List<dynamic>;

  List<dynamic> pdfNames = [];
  List<dynamic> recentFiles = [];
  List suggestedFiles;

  @override
  Widget build(BuildContext context) {
    for (int i = 0; i < files.length; i++) {
      pdfNames.add(Hive.box('pdfs').getAt(0)[i][0].split('/').last);
    }
    final int remove = (3 * pdfNames.length / 16).floor();

    pdfNames.removeRange(files.length, pdfNames.length);
    pdfNames = pdfNames.map((element) => element.toLowerCase()).toList();
    recentFiles = pdfNames.sublist(
        0, pdfNames.length - remove); //will list top 5 pdfs only

    suggestedFiles = query.isEmpty
        ? recentFiles
        : pdfNames
            .where((p) => p.startsWith(query.toLowerCase()) as bool)
            .toList();
    print(query);
    print(remove);
    return ListView.builder(
      itemBuilder: (context, index) => ListTile(
        onTap: () {
          final List<dynamic> finalList = [];
          for (int i = 0; i < files.length; i++) {
            finalList.add(files[i][0]);
          }
          final String fileLocation =
              '${finalList.where((element) => element.toString().split('/').last == suggestedFiles[index])}';
          print(finalList);

          final String fileLoc = fileLocation.split('(').last.split(')').first;

          OpenFile.open(fileLoc);
        },
        leading: Icon(query.isEmpty
            ? Icons.youtube_searched_for_rounded
            : Icons.picture_as_pdf_rounded),
        title: Text(suggestedFiles[index] as String),
      ),
      itemCount: suggestedFiles.length,
    );
  }
}
