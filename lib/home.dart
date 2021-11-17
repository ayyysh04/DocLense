import 'dart:async';
import 'dart:io';
import 'package:doclense/constants/route_constants.dart';
import 'package:doclense/main_drawer.dart';
import 'package:doclense/providers/image_list.dart';
import 'package:doclense/providers/theme_provider.dart';
import 'package:doclense/services/search_service.dart';
import 'package:doclense/ui_components/double_back_to_close_snackbar.dart';
import 'package:doclense/utils/home_utils/delete_onpressed.dart';
import 'package:doclense/utils/home_utils/fav_onpressed.dart';
import 'package:doclense/utils/home_utils/move_to_folder_onpressed.dart';
import 'package:doclense/utils/home_utils/rename_onpressed.dart';
import 'package:doclense/utils/home_utils/search_widget.dart';
import 'package:doclense/utils/image_converter.dart';
import 'package:double_back_to_close_app/double_back_to_close_app.dart';
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
  String query = "";

  bool _showSearch = false;
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
  TextEditingController controller;
  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
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

  @override
  Widget build(BuildContext context) {
//    return ChangeNotifierProvider.value(
//      value:imagelist;
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return OrientationBuilder(builder: (BuildContext, orientation) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        drawer: MainDrawer(),
        appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.black),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Image(
                image: AssetImage(
                  "assets/app_icon.png",
                ),
                width: 30,
                height: 30,
                fit: BoxFit.contain,
                color: Colors.blueAccent,
              ),
              const SizedBox(
                width: 10,
              ),
              const Text(
                'DocLense',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: SizedBox(
                                height: 50,
                                child: TextField(
                                  controller: controller,
                                  onTap: () {
                                    setState(() {
                                      _showSearch = true;
                                    });

                                    // showSearch(
                                    //     context: context, delegate: SearchService());
                                  },
                                  onChanged: (val) {
                                    setState(() {
                                      query = val;
                                    });
                                  },
                                  focusNode: _searchBarNode,
                                  decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.all(0),
                                      prefixIcon: const Icon(Icons.search),
                                      suffixIcon: GestureDetector(
                                        child: const Icon(
                                          Icons.close,
                                        ),
                                        onTap: () {
                                          controller.clear();
                                          setState(() {
                                            query = "";
                                            _showSearch = false;
                                          });
                                          _searchBarNode.unfocus();
                                        },
                                      ),
                                      border: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                            color: Colors.transparent),
                                        borderRadius:
                                            BorderRadius.circular(15.0),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                            color: Colors.transparent),
                                        borderRadius:
                                            BorderRadius.circular(15.0),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                            color: Colors.transparent),
                                        borderRadius:
                                            BorderRadius.circular(15.0),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                            color: Colors.transparent),
                                        borderRadius:
                                            BorderRadius.circular(15.0),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                            color: Colors.transparent),
                                        borderRadius:
                                            BorderRadius.circular(15.0),
                                      ),
                                      filled: true,
                                      hintStyle:
                                          TextStyle(color: Colors.grey[600]),
                                      hintText: "Search your files",
                                      fillColor: Colors.grey[200]),
                                ))),
                        const SizedBox(
                          width: 10,
                        ),
                        IconButton(
                            onPressed: () {
                              setState(() {});
                            },
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.blueAccent,
                            ))
                      ],
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    Row(
                      children: [
                        Text(
                          _showSearch
                              ? query.isEmpty
                                  ? "Recent Scans"
                                  : "Results"
                              : "All Scans",
                          style: TextStyle(
                              fontSize: 25, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    if (_isLoading)
                      const Expanded(
                        child: SpinKitRotatingCircle(
                          color: Colors.blue,
                        ),
                      )
                    else
                      DoubleBackToCloseApp(
                        snackBar: doubleBackToCloseSnackBar(),
                        child: ValueListenableBuilder(
                          valueListenable: Hive.box('pdfs').listenable(),
                          builder: (context, Box<dynamic> pdfsBox, widget) {
                            if (pdfsBox.getAt(0).length == 0) {
                              return Expanded(
                                child: Center(
                                  child: Text(
                                    "No PDFs Scanned Yet !! ",
                                  ),
                                ),
                              );
                            }
                            return Expanded(
                              child: NotificationListener<
                                  OverscrollIndicatorNotification>(
                                onNotification: (OverscrollIndicatorNotification
                                    overscroll) {
                                  overscroll.disallowGlow();
                                  return;
                                },
                                child: _showSearch
                                    ? SearchListView(query: query)
                                    : ListView.separated(
                                        separatorBuilder:
                                            (context, int index) =>
                                                const Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 10),
                                          child: Divider(
                                            color: Colors.grey,
                                            height: 5,
                                          ),
                                        ),
                                        itemCount:
                                            pdfsBox.getAt(0).length as int,
                                        itemBuilder: (context, index) {
                                          final Image previewImage =
                                              ImageConverter
                                                  .base64StringToImage(
                                                      pdfsBox.getAt(0)[index][2]
                                                          as String);
                                          return GestureDetector(
                                            onTap: () {
                                              OpenFile.open(
                                                  pdfsBox.getAt(0)[index][0]
                                                      as String);
                                            },
                                            child: SizedBox(
                                              height: 100,
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                children: [
                                                  SizedBox(
                                                    width: 100,
                                                    height: 100,
                                                    child: previewImage,
                                                  ),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        (pdfsBox.getAt(0)[index]
                                                                [0] as String)
                                                            .split('/')
                                                            .last,
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                      Row(
                                                        children: [
                                                          Text(
                                                            '${pdfsBox.getAt(0)[index][1]}',
                                                            style:
                                                                const TextStyle(
                                                                    color: Colors
                                                                        .grey),
                                                          ),
                                                          Container(
                                                            margin:
                                                                const EdgeInsets
                                                                        .symmetric(
                                                                    horizontal:
                                                                        5),
                                                            width: 5,
                                                            height: 5,
                                                            decoration:
                                                                const BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                          ),
                                                          const Text("12:01 PM",
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .grey)),
                                                        ],
                                                      ),
                                                      SingleChildScrollView(
                                                        scrollDirection:
                                                            Axis.horizontal,
                                                        child: Row(
                                                          children: [
                                                            IconButton(
                                                                icon: Icon(
                                                                  Icons.share,
                                                                  color: themeChange
                                                                          .darkTheme
                                                                      ? Colors
                                                                          .white70
                                                                      : Colors
                                                                          .blueAccent,
                                                                  size: tablet
                                                                      ? 40.0
                                                                      : 25.0,
                                                                ),
                                                                onPressed:
                                                                    () async {
                                                                  final File
                                                                      file =
                                                                      File(await pdfsBox.getAt(0)[index]
                                                                              [
                                                                              0]
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
                                                                      : Colors
                                                                          .blueAccent,
                                                                  size: tablet
                                                                      ? 40.0
                                                                      : 25.0,
                                                                ),
                                                                onPressed:
                                                                    () async {
                                                                  deleteOnPressed(
                                                                      setState:
                                                                          () {
                                                                        setState(
                                                                            () {});
                                                                      },
                                                                      context:
                                                                          context,
                                                                      pdfsBox:
                                                                          pdfsBox,
                                                                      index:
                                                                          index);
                                                                }),
                                                            IconButton(
                                                              icon: Icon(
                                                                Icons.edit,
                                                                color: themeChange
                                                                        .darkTheme
                                                                    ? Colors
                                                                        .white70
                                                                    : Colors
                                                                        .blueAccent,
                                                                size: tablet
                                                                    ? 40.0
                                                                    : 25.0,
                                                              ),
                                                              onPressed: () {
                                                                renameOnPressed(
                                                                    setState:
                                                                        () {
                                                                      setState(
                                                                          () {});
                                                                    },
                                                                    context:
                                                                        context,
                                                                    pdfsBox:
                                                                        pdfsBox,
                                                                    index:
                                                                        index);
                                                              },
                                                            ),
                                                            IconButton(
                                                              icon: Icon(
                                                                Icons
                                                                    .drive_file_move,
                                                                color: themeChange
                                                                        .darkTheme
                                                                    ? Colors
                                                                        .white70
                                                                    : Colors
                                                                        .blueAccent,
                                                                size: tablet
                                                                    ? 40.0
                                                                    : 25.0,
                                                              ),
                                                              onPressed:
                                                                  () async {
                                                                await moveToFolder(
                                                                    context:
                                                                        context,
                                                                    index:
                                                                        index,
                                                                    pdfsBox:
                                                                        pdfsBox,
                                                                    setState:
                                                                        () {
                                                                      setState(
                                                                          () {});
                                                                    });
                                                              },
                                                            ),
                                                            IconButton(
                                                              icon: Icon(
                                                                isStarred(
                                                                        pdfsBox,
                                                                        index)
                                                                    ? Icons.star
                                                                    : Icons
                                                                        .star_border,
                                                                color: themeChange
                                                                        .darkTheme
                                                                    ? Colors
                                                                        .white70
                                                                    : Colors
                                                                        .blueAccent,
                                                                size: tablet
                                                                    ? 40.0
                                                                    : 25.0,
                                                              ),
                                                              onPressed:
                                                                  () async {
                                                                favOnPressed(
                                                                    setState:
                                                                        () {
                                                                      setState(
                                                                          () {});
                                                                    },
                                                                    context:
                                                                        context,
                                                                    pdfsBox:
                                                                        pdfsBox,
                                                                    index:
                                                                        index);
                                                              },
                                                            )
                                                          ],
                                                        ),
                                                      )
                                                    ],
                                                  )
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              if (orientation == Orientation.landscape)
                Column(
                  // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Spacer(
                      flex: 1,
                    ),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            shadowColor: Colors.transparent,
                            primary: Colors.transparent,
                            shape: CircleBorder(
                              side:
                                  BorderSide(color: Colors.grey[300], width: 3),
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
                        onPressed: () async {
                          await getImage(ImageSource.gallery);
                        }),
                    Spacer(),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            shadowColor: Colors.transparent,
                            primary: Colors.transparent,
                            shape: CircleBorder(
                              side:
                                  BorderSide(color: Colors.grey[300], width: 3),
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
                            Icons.camera_alt_rounded,
                            size: 30,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () {
                          getImage(ImageSource.camera);
                        }),
                    Spacer(
                      flex: 5,
                    )
                  ],
                ),
            ],
          ),
        ),
        // floatingActionButton: FloatingActionButton.extended(
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

        bottomNavigationBar: orientation == Orientation.portrait
            ? Padding(
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
                              side:
                                  BorderSide(color: Colors.grey[300], width: 3),
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
                        onPressed: () async {
                          await getImage(ImageSource.gallery);
                        }),
                    Spacer(),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            shadowColor: Colors.transparent,
                            primary: Colors.transparent,
                            shape: CircleBorder(
                              side:
                                  BorderSide(color: Colors.grey[300], width: 3),
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
                            Icons.camera_alt_rounded,
                            size: 30,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () {
                          getImage(ImageSource.camera);
                        }),
                    Spacer(
                      flex: 8,
                    )
                  ],
                ),
              )
            : null,
      );
    });
  }
}
