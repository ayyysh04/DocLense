import 'dart:async';
import 'dart:io';
import 'package:doclense/constants/route_constants.dart';
import 'package:doclense/main_drawer.dart';
import 'package:doclense/providers/image_list.dart';
import 'package:doclense/providers/theme_provider.dart';
import 'package:doclense/services/search_service.dart';
import 'package:doclense/ui_components/double_back_to_close_snackbar.dart';
import 'package:doclense/utils/image_converter.dart';
import 'package:double_back_to_close_app/double_back_to_close_app.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets/forms.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum IconOptions { share }
enum DeviceType { Phone, Tablet }

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool tablet = false;
  Future setSharedPreferences() async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    if (sharedPreferences.getStringList('savedFiles') == null) {
      sharedPreferences.setStringList('savedFiles', []);
      return [];
    } else {
      return sharedPreferences.getStringList('savedFiles');
    }
  }

  bool getDeviceType() {
    final data = MediaQueryData.fromWindow(WidgetsBinding.instance.window);
    if (data.size.shortestSide < 550) {
      return false;
    } else {
      return true;
    }
  }

  ImageList images = ImageList();
  QuickActions quickActions = QuickActions();

  void _navigate(String routeName) {
    Navigator.of(context).pushNamed(routeName);
  }

  // File imageFile;

  final picker = ImagePicker();

  Future<void> getImage(ImageSource imageSource) async {
    final PickedFile imageFile = await picker.getImage(source: imageSource);
    if (imageFile == null) return;
    final File tmpFile = File(imageFile.path);
    // final appDir = await syspaths.getApplicationDocumentsDirectory();
    // final fileName = path.basename(imageFile.path);
    // final localFile = await tmpFile.copy('${appDir.path}/$fileName');

    if (imageSource == ImageSource.camera) {
      GallerySaver.saveImage(tmpFile.path)
          .then((value) => print("Image Saved"));
    }

    Navigator.of(context).pushNamed(
      RouteConstants.imageView,
      arguments: {
        'imageFile': tmpFile,
        'imageList': images,
      },
    );
  }

  FocusNode _searchBarNode;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchBarNode = FocusNode();
    // setSharedPreferences().then((value) {
    //   savedPdfs = value;
    //   print('Saved : $savedPdfs');
    // });
    tablet = getDeviceType();
    quickActions.initialize((String shortcutType) {
      switch (shortcutType) {
        case 'about':
          return _navigate(RouteConstants.aboutAppScreen);
        case 'starredDocument':
          return _navigate(RouteConstants.starredDocumentsScreen);
        case 'setting':
          return _navigate(RouteConstants.settingsScreen);

        default:
          MaterialPageRoute(builder: (_) {
            return Scaffold(
              body: Center(
                child: Text('No Page defined for $shortcutType'),
              ),
            );
          });
      }
    });

    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
          type: 'about', localizedTitle: 'About DocLense', icon: 'info'),
      const ShortcutItem(
          type: 'starredDocument',
          localizedTitle: 'Starred Documents',
          icon: 'starred'),
      const ShortcutItem(
          type: 'setting', localizedTitle: 'Settings', icon: 'setting'),
    ]);

    Future.delayed(
        const Duration(
          seconds: 2,
        ), () {
      setState(() {
        _isLoading = false;
      });
    });
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

  @override
  Widget build(BuildContext context) {
//    return ChangeNotifierProvider.value(
//      value:imagelist;
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GestureDetector(
      onTap: () {
        _searchBarNode.unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        drawer: MainDrawer(),
        appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.black),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Image(
                image: AssetImage(
                  "assets/app_icon.png",
                ),
                width: 30,
                height: 30,
                fit: BoxFit.contain,
                color: Colors.blueAccent,
              ),
              SizedBox(
                width: 10,
              ),
              const Text(
                'DocLense',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          // actions: <Widget>[
          //   IconButton(
          //     icon: const Icon(Icons.search),
          //     onPressed: () {
          //       showSearch(context: context, delegate: SearchService());
          //     },
          //   ),
          //   IconButton(
          //     icon: const Icon(Icons.refresh),
          //     onPressed: () {
          //       setState(() {});
          //     },
          //   ),
          // ],
        ),
        // ignore: deprecated_member_use
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: 30,
                ),
                Row(
                  children: [
                    Expanded(
                        child: SizedBox(
                            height: 50,
                            child: TextField(
                              focusNode: _searchBarNode,
                              decoration: InputDecoration(
                                  contentPadding: EdgeInsets.all(0),
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.transparent),
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.transparent),
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.transparent),
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.transparent),
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.transparent),
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  filled: true,
                                  hintStyle: TextStyle(color: Colors.grey[600]),
                                  hintText: "Search your files",
                                  fillColor: Colors.grey[200]),
                            ))),
                    SizedBox(
                      width: 10,
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.create_new_folder_outlined,
                        color: Colors.blueAccent,
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.refresh,
                          color: Colors.blueAccent,
                        ))
                  ],
                ),
                SizedBox(
                  height: 30,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "My Scans",
                      style:
                          TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                        onPressed: () {},
                        child: Row(
                          children: [
                            Text(
                              "See All",
                              style: TextStyle(
                                  fontSize: 15, color: Colors.blueAccent),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.blueAccent,
                            )
                          ],
                        ))
                  ],
                ),
                Container(
                  height: 210,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 20,
                    separatorBuilder: (BuildContext context, int index) =>
                        const VerticalDivider(
                      width: 5,
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 140,
                            width: 140,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(20)),
                              color: Colors.amber[100],
                            ),
                            child: Icon(
                              Icons.folder,
                              size: 80,
                              color: Colors.amber,
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            "Design",
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            "32 items",
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Row(
                  children: [
                    const Text(
                      "Recent Scans",
                      style:
                          TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                Container(
                  height: 200,
                  child: ListView.separated(
                    itemCount: 20,
                    separatorBuilder: (BuildContext context, int index) =>
                        Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: const Divider(
                        color: Colors.grey,
                        height: 5,
                      ),
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      return Container(
                        height: 100,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 60,
                              height: 60,
                              child: Placeholder(),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Design",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      "10/01/2021",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    Container(
                                      margin:
                                          EdgeInsets.symmetric(horizontal: 5),
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text("12:01 PM",
                                        style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    TextButton.icon(
                                      label: Text("Print"),
                                      icon: Icon(Icons.print),
                                      onPressed: () {},
                                    ),
                                    TextButton.icon(
                                      label: Text("share"),
                                      icon: Icon(Icons.share_rounded),
                                      onPressed: () {},
                                    )
                                  ],
                                )
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
                _isLoading
                    ? const SpinKitRotatingCircle(
                        color: Colors.blue,
                      )
                    : DoubleBackToCloseApp(
                        snackBar: doubleBackToCloseSnackBar(),
                        child: ValueListenableBuilder(
                          valueListenable: Hive.box('pdfs').listenable(),
                          builder: (context, Box<dynamic> pdfsBox, widget) {
                            if (pdfsBox.getAt(0).length == 0) {
                              return const Center(
                                child: Text("No PDFs Scanned Yet !! "),
                              );
                            }
                            return ListView.builder(
                              itemCount: pdfsBox.getAt(0).length as int,
                              itemBuilder: (context, index) {
                                final Image previewImage =
                                    ImageConverter.base64StringToImage(
                                        pdfsBox.getAt(0)[index][2] as String);
                                return GestureDetector(
                                  onTap: () {
                                    OpenFile.open(
                                        pdfsBox.getAt(0)[index][0] as String);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Container(
                                      height: MediaQuery.of(context)
                                                  .orientation ==
                                              Orientation.landscape
                                          ? MediaQuery.of(context).size.height /
                                              2.5
                                          : MediaQuery.of(context).size.height /
                                              5,
                                      child: Card(
                                        elevation: 5,
                                        color: themeChange.darkTheme
                                            ? Colors.grey[700]
                                            : Colors.white,
                                        child: Row(
                                          // mainAxisAlignment: MainAxisAlignment.spaceAround,
                                          children: [
                                            Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  4,
                                              child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: previewImage),
                                            ),
                                            Expanded(
                                              child: Container(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceAround,
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      child: Text(
                                                          (pdfsBox.getAt(
                                                                      0)[index]
                                                                  [0] as String)
                                                              .split('/')
                                                              .last,
                                                          style: TextStyle(
                                                              fontSize: tablet
                                                                  ? 30
                                                                  : 20)),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets
                                                          .fromLTRB(8, 0, 8, 8),
                                                      child: Text(
                                                          '${pdfsBox.getAt(0)[index][1]}',
                                                          style: TextStyle(
                                                              fontSize: tablet
                                                                  ? 20
                                                                  : 13)),
                                                    ),
                                                    SizedBox(
                                                        height: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .height *
                                                            0.01),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceEvenly,
                                                      children: [
                                                        IconButton(
                                                            icon: Icon(
                                                              Icons.share,
                                                              color: themeChange
                                                                      .darkTheme
                                                                  ? Colors
                                                                      .white70
                                                                  : Colors.grey,
                                                              size: tablet
                                                                  ? 40.0
                                                                  : 20.0,
                                                            ),
                                                            onPressed:
                                                                () async {
                                                              final File file =
                                                                  File(await pdfsBox
                                                                          .getAt(
                                                                              0)[index][0]
                                                                      as String);

                                                              final path =
                                                                  file.path;

                                                              print(path);

                                                              Share.shareFiles(
                                                                  [path],
                                                                  text:
                                                                      'Your PDF!');
                                                            }),
                                                        IconButton(
                                                            icon: Icon(
                                                              Icons.delete,
                                                              color: themeChange
                                                                      .darkTheme
                                                                  ? Colors
                                                                      .white70
                                                                  : Colors.grey,
                                                              size: tablet
                                                                  ? 40.0
                                                                  : 20.0,
                                                            ),
                                                            onPressed:
                                                                () async {
                                                              showDialog(
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (BuildContext
                                                                          ctx) {
                                                                    return AlertDialog(
                                                                      backgroundColor:
                                                                          Colors
                                                                              .blueGrey[800],
                                                                      title:
                                                                          const Text(
                                                                        "The PDF will be permanently deleted.\nDo you want to proceed?",
                                                                        textAlign:
                                                                            TextAlign.center,
                                                                        style: TextStyle(
                                                                            color:
                                                                                Colors.white),
                                                                      ),
                                                                      content:
                                                                          SingleChildScrollView(
                                                                        child:
                                                                            ListBody(
                                                                          children: <
                                                                              Widget>[
                                                                            GestureDetector(
                                                                                onTap: () {
                                                                                  final File sourceFile = File(pdfsBox.getAt(0)[index][0] as String);
                                                                                  print(sourceFile.path);
                                                                                  sourceFile.delete();
                                                                                  final List<dynamic> starredFiles = Hive.box('starred').getAt(0) as List<dynamic>;
                                                                                  setState(() {
                                                                                    pdfsBox.getAt(0).removeAt(index);
                                                                                    final List<dynamic> editedList = pdfsBox.getAt(0) as List<dynamic>;
                                                                                    pdfsBox.putAt(0, editedList);
                                                                                    final List<dynamic> finalStarredFiles = [];
                                                                                    for (int i = 0; i < starredFiles.length; i++) {
                                                                                      finalStarredFiles.add(starredFiles[i][0]);
                                                                                    }
                                                                                    if (finalStarredFiles.contains(sourceFile.path)) {
                                                                                      print('yes');
                                                                                      for (int i = 0; i < finalStarredFiles.length; i++) {
                                                                                        if (Hive.box('starred').getAt(0)[i][0] == sourceFile.path) {
                                                                                          print('yes');
                                                                                          Hive.box('starred').getAt(0).removeAt(i);
                                                                                          final List<dynamic> editedList = Hive.box('starred').getAt(0) as List<dynamic>;
                                                                                          Hive.box('starred').putAt(0, editedList);
                                                                                          break;
                                                                                        }
                                                                                      }
                                                                                    }
                                                                                  });
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
                                                            }),
                                                        IconButton(
                                                          icon: Icon(
                                                            Icons.edit,
                                                            color: themeChange
                                                                    .darkTheme
                                                                ? Colors.white70
                                                                : Colors.grey,
                                                            size: tablet
                                                                ? 40.0
                                                                : 20.0,
                                                          ),
                                                          onPressed: () {
                                                            TextEditingController
                                                                pdfName;
                                                            showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (BuildContext
                                                                        dialogContext) {
                                                                  pdfName =
                                                                      TextEditingController();
                                                                  return AlertDialog(
                                                                    title:
                                                                        const Text(
                                                                      "Rename",
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                      style: TextStyle(
                                                                          fontWeight: FontWeight
                                                                              .bold,
                                                                          fontSize:
                                                                              20),
                                                                    ),
                                                                    content:
                                                                        SizedBox(
                                                                      height:
                                                                          MediaQuery.of(context).size.height /
                                                                              5,
                                                                      child: Column(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.center,
                                                                          children: [
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
                                                                                final List<dynamic> starred = Hive.box('starred').getAt(0) as List<dynamic>;
                                                                                final List<dynamic> finalStarred = [];
                                                                                for (int i = 0; i < starred.length; i++) {
                                                                                  finalStarred.add(starred[i][0]);
                                                                                }
                                                                                print("PDFS : ${Hive.box('pdfs').getAt(0)}");
                                                                                final File sourceFile = File(pdfsBox.getAt(0)[index][0] as String);
                                                                                setState(() {
                                                                                  if (finalStarred.contains(pdfsBox.getAt(0)[index][0])) {
                                                                                    print('yes');
                                                                                    for (int i = 0; i < finalStarred.length; i++) {
                                                                                      if (Hive.box('starred').getAt(0)[i][0] == sourceFile.path) {
                                                                                        print('yes');
                                                                                        final List<String> path = (Hive.box('starred').getAt(0)[i][0] as String).split('/');
                                                                                        path.last = "${pdfName.text}.pdf";
                                                                                        Hive.box('starred').getAt(0)[i][0] = path.join('/');
                                                                                        final List<dynamic> editedList = Hive.box('starred').getAt(0) as List<dynamic>;
                                                                                        Hive.box('starred').putAt(0, editedList);
                                                                                        break;
                                                                                      }
                                                                                    }
                                                                                  }
                                                                                  final List<String> path = pdfsBox.getAt(0)[index][0].split('/') as List<String>;
                                                                                  path.last = "${pdfName.text}.pdf";
                                                                                  pdfsBox.getAt(0)[index][0] = path.join('/');
                                                                                });
                                                                                sourceFile.renameSync(pdfsBox.getAt(0)[index][0] as String);
                                                                                print("PDFS : ${Hive.box('pdfs').getAt(0)}");
                                                                                final List<dynamic> editedList = pdfsBox.getAt(0) as List<dynamic>;
                                                                                pdfsBox.putAt(0, editedList);
                                                                                Navigator.pop(dialogContext);
                                                                              },
                                                                              child: const Text("Save"),
                                                                            ),
                                                                          ]),
                                                                    ),
                                                                  );
                                                                });
                                                          },
                                                        ),
                                                        IconButton(
                                                          icon: Icon(
                                                            Icons
                                                                .drive_file_move,
                                                            color: themeChange
                                                                    .darkTheme
                                                                ? Colors.white70
                                                                : Colors.grey,
                                                            size: tablet
                                                                ? 40.0
                                                                : 20.0,
                                                          ),
                                                          onPressed: () async {
                                                            final status =
                                                                await Permission
                                                                    .storage
                                                                    .status;
                                                            if (!status
                                                                .isGranted) {
                                                              await Permission
                                                                  .storage
                                                                  .request();
                                                            }
                                                            final String
                                                                oldPath =
                                                                pdfsBox.getAt(
                                                                            0)[
                                                                        index][0]
                                                                    as String;
                                                            String newPath;
                                                            final String path =
                                                                await ExtStorage
                                                                    .getExternalStorageDirectory();
                                                            final Directory
                                                                directory =
                                                                Directory(path);
                                                            Navigator.of(
                                                                    context)
                                                                .pushNamed(
                                                              RouteConstants
                                                                  .folderPickerPage,
                                                              arguments: {
                                                                'rootDirectory':
                                                                    directory,
                                                                'action': (BuildContext
                                                                        context,
                                                                    Directory
                                                                        folder) async {
                                                                  newPath =
                                                                      '${folder.path}/${(pdfsBox.getAt(0)[index][0] as String).split('/').last}';
                                                                  print(
                                                                      newPath);
                                                                  if (newPath !=
                                                                      null) {
                                                                    final List<
                                                                        dynamic> starred = Hive.box(
                                                                            'starred')
                                                                        .getAt(
                                                                            0) as List<
                                                                        dynamic>;
                                                                    final List<
                                                                            dynamic>
                                                                        finalStarred =
                                                                        [];
                                                                    for (int i =
                                                                            0;
                                                                        i < starred.length;
                                                                        i++) {
                                                                      finalStarred.add(
                                                                          starred[i]
                                                                              [
                                                                              0]);
                                                                    }
                                                                    final File
                                                                        sourceFile =
                                                                        File(
                                                                            oldPath);
                                                                    if (finalStarred.contains(
                                                                        pdfsBox.getAt(0)[index]
                                                                            [
                                                                            0])) {
                                                                      print(
                                                                          'yes');
                                                                      for (int i =
                                                                              0;
                                                                          i < finalStarred.length;
                                                                          i++) {
                                                                        if (Hive.box('starred').getAt(0)[i][0] ==
                                                                            sourceFile.path) {
                                                                          print(
                                                                              'yes');
                                                                          await sourceFile
                                                                              .copy(newPath);
                                                                          await sourceFile
                                                                              .delete();

                                                                          Hive.box('starred').getAt(0)[i][0] =
                                                                              newPath;
                                                                          pdfsBox.getAt(0)[index][0] =
                                                                              newPath;
                                                                          final List<dynamic>
                                                                              editedList =
                                                                              Hive.box('starred').getAt(0) as List<dynamic>;
                                                                          Hive.box('starred').putAt(
                                                                              0,
                                                                              editedList);
                                                                          final List<dynamic>
                                                                              pdfEditedList =
                                                                              pdfsBox.getAt(0) as List<dynamic>;
                                                                          pdfsBox.putAt(
                                                                              0,
                                                                              pdfEditedList);
                                                                          break;
                                                                        }
                                                                      }
                                                                    } else {
                                                                      print(
                                                                          "Newpath: $newPath");
                                                                      await sourceFile
                                                                          .copy(
                                                                              newPath);
                                                                      await sourceFile
                                                                          .delete();
                                                                      setState(
                                                                          () {
                                                                        pdfsBox.getAt(0)[index][0] =
                                                                            newPath;
                                                                      });
                                                                    }
                                                                  }
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop();
                                                                },
                                                              },
                                                            );
                                                          },
                                                        ),
                                                        IconButton(
                                                          icon: Icon(
                                                            isStarred(pdfsBox,
                                                                    index)
                                                                ? Icons.star
                                                                : Icons
                                                                    .star_border,
                                                            color: themeChange
                                                                    .darkTheme
                                                                ? Colors.white70
                                                                : Colors.grey,
                                                            size: tablet
                                                                ? 40.0
                                                                : 20.0,
                                                          ),
                                                          onPressed: () async {
                                                            print(isStarred(
                                                                pdfsBox,
                                                                index));
                                                            final File file = File(
                                                                await pdfsBox.getAt(
                                                                            0)[
                                                                        index][0]
                                                                    as String);
                                                            final path =
                                                                file.path;
                                                            final date = pdfsBox
                                                                    .getAt(0)[
                                                                index][1];
                                                            final imagePreview =
                                                                pdfsBox.getAt(
                                                                        0)[
                                                                    index][2];

                                                            final List<dynamic>
                                                                files =
                                                                Hive.box('starred')
                                                                        .getAt(
                                                                            0)
                                                                    as List<
                                                                        dynamic>;

                                                            final List<dynamic>
                                                                starredDocs =
                                                                [];

                                                            for (int i = 0;
                                                                i <
                                                                    files
                                                                        .length;
                                                                i++) {
                                                              starredDocs.add(
                                                                  files[i][0]);
                                                            }
                                                            if (starredDocs
                                                                .contains(
                                                                    path)) {
                                                              for (int i = 0;
                                                                  i <
                                                                      starredDocs
                                                                          .length;
                                                                  i++) {
                                                                if (Hive.box('starred')
                                                                            .getAt(0)[
                                                                        i][0] ==
                                                                    path) {
                                                                  Hive.box(
                                                                          'starred')
                                                                      .getAt(0)
                                                                      .removeAt(
                                                                          i);
                                                                  break;
                                                                }
                                                              }
                                                              setState(() {});
                                                              ScaffoldMessenger
                                                                      .of(
                                                                          context)
                                                                  .showSnackBar(
                                                                      const SnackBar(
                                                                          content:
                                                                              Text('Removed from starred documents')));
                                                              print(
                                                                  'Already fav');
                                                            } else {
                                                              files.add([
                                                                path,
                                                                date,
                                                                imagePreview
                                                              ]);
                                                              Hive.box(
                                                                      'starred')
                                                                  .putAt(
                                                                      0, files);
                                                              print(
                                                                  "STARRED : ${Hive.box('starred').getAt(0)}");
                                                              ScaffoldMessenger
                                                                      .of(
                                                                          context)
                                                                  .showSnackBar(
                                                                      const SnackBar(
                                                                          content:
                                                                              Text('Added to starred documents!')));
                                                            }
                                                            setState(() {});
                                                          },
                                                        )
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
              ],
            ),
          ),
        ),
        // floatingActionButtonLocation:
        //     FloatingActionButtonLocation.centerFloat,
        // floatingActionButton: Stack(
        //   alignment: Alignment.center,
        //   children: [
        //     Positioned(
        //       left: 40,
        //       bottom: 0,
        //       child: FloatingActionButton(
        //         onPressed: () {},
        //       ),
        //     ),
        //     FloatingActionButton(onPressed: () {}),
        //   ],
        // )
        //  FloatingActionButton.extended(
        //   onPressed: () {},
        //   label: Row(
        //     mainAxisSize: MainAxisSize.min,
        //     children: <Widget>[
        //       IconButton(
        //         iconSize: 30,
        //         icon: const Icon(
        //           Icons.camera_alt,
        //         ),
        //         onPressed: () async {
        //           getImage(ImageSource.camera);
        //         },
        //       ),
        //       SizedBox(height: MediaQuery.of(context).size.height * 0.01),
        //       SizedBox(height: MediaQuery.of(context).size.height * 0.01),
        //       SizedBox(width: MediaQuery.of(context).size.width * 0.01),
        //       IconButton(
        //         iconSize: 30,
        //         icon: const Icon(
        //           Icons.image,
        //         ),
        //         onPressed: () {
        //           getImage(ImageSource.gallery);
        //         },
        //       )
        //     ],
        //   ),
        // ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Row(
            // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Spacer(
                flex: 2,
              ),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      shadowColor: Colors.transparent,
                      primary: Colors.transparent,
                      shape: CircleBorder(
                        side: BorderSide(color: Colors.grey[300], width: 3),
                      ),
                      padding: EdgeInsets.all(10)),
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.4),
                            blurRadius: 8.0,
                            spreadRadius: 4,
                            offset: Offset(
                              0.0,
                              3.0,
                            ),
                          ),
                        ]),
                    child: Icon(
                      Icons.photo,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  onPressed: () {}),
              Spacer(),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      shadowColor: Colors.transparent,
                      primary: Colors.transparent,
                      shape: CircleBorder(
                        side: BorderSide(color: Colors.grey[300], width: 3),
                      ),
                      padding: EdgeInsets.all(10)),
                  child: Container(
                    padding: EdgeInsets.all(30),
                    decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.4),
                            blurRadius: 8.0,
                            spreadRadius: 4,
                            offset: Offset(
                              0.0,
                              3.0,
                            ),
                          ),
                        ]),
                    child: Icon(
                      Icons.document_scanner_rounded,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () {}),
              Spacer(
                flex: 8,
              )
            ],
          ),
        ),
      ),
    );
  }
}
