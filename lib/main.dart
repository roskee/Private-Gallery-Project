import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'file.dart';
import 'package:unicorndial/unicorndial.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:photo_view/photo_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

// file_picker video_player path_provider
// shared_preferences feature_discovery
// english_words lottie
// import 'package:flutter/scheduler.dart'
// unicorndial fluttertoast
void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MyAppState();
  }
}

class MyFileSelectionItem {
  MyFile myFile;
  String thumb;
  bool isSelected = false;
  bool isThumbReady = false;
  MyFileSelectionItem(this.myFile, VoidCallback function) {
    myFile.getThumb().then((value) {
      thumb = value;
      isThumbReady = true;
      function();
    });
  }
}

class MyAppState extends State<StatefulWidget>
    with SingleTickerProviderStateMixin {
  static const platform  = const MethodChannel('samples.flutter.dev/battery');
  String _batteryLevel = 'Unknown';
  Future<void> _getBatteryLevel() async{
    String batteryLevel;
    String uri = "/Downloads";
    try{
      await platform.invokeMethod('openFilePicker',{"uri": uri});
      //batteryLevel = 'Battery Level at $result %';
    } on PlatformException catch(e){
      batteryLevel = 'failed to get battery level';
    }
    // setState(() {
    //       _batteryLevel = batteryLevel;
    //     });
  }
  TabController _tabController;
  PageController _introPageController = PageController();
  bool onSelection = false;
  bool encryptionDone = true;
  bool passwordNotMatched = false;
  bool isFingerPrintSet = false;
  bool isPreferencesReady = false;
  bool areFilesReady = false;
  bool areThumbsReady = false;
  int theme = 0;
  String _password;
  String _tempPassword1, _tempPassword2;
  FocusNode passwordRepeatNode = FocusNode();
  FileControl _fileControl;
  SharedPreferences _preferences;
  Map<String, List< /*File*/ String>> _thumbs;

  bool isSelecting = false;
  List<MyFileSelectionItem> imageSelectedList;
  List<MyFileSelectionItem> videoSelectedList;
  List<MyFileSelectionItem> otherSelectedList;
  void select(String type, int index) {
    if (type == MyFile.IMAGE)
      imageSelectedList[index].isSelected =
          !imageSelectedList[index].isSelected;
    else if (type == MyFile.VIDEO)
      videoSelectedList[index].isSelected =
          !videoSelectedList[index].isSelected;
    else
      otherSelectedList[index].isSelected =
          !otherSelectedList[index].isSelected;
  }

  void selectAll(String type) {
    if (type == MyFile.IMAGE) {
      bool value = imageSelectedList.any((element) => !element.isSelected);
      imageSelectedList.forEach((element) {
        element.isSelected = value;
      });
    } else if (type == MyFile.VIDEO) {
      bool value = videoSelectedList.any((element) => !element.isSelected);
      videoSelectedList.forEach((element) {
        element.isSelected = value;
      });
    } else {
      bool value = otherSelectedList.any((element) => !element.isSelected);
      otherSelectedList.forEach((element) {
        element.isSelected = value;
      });
    }
  }

  int getSelectionCount() {
    int count = 0;
    imageSelectedList.forEach((element) {
      if (element.isSelected) count++;
    });
    videoSelectedList.forEach((element) {
      if (element.isSelected) count++;
    });
    otherSelectedList.forEach((element) {
      if (element.isSelected) count++;
    });
    return count;
  }

  void unSelectAll() {
    imageSelectedList.forEach((element) {
      element.isSelected = false;
    });
    videoSelectedList.forEach((element) {
      element.isSelected = false;
    });
    otherSelectedList.forEach((element) {
      element.isSelected = false;
    });
  }

  void deleteSelected() {}

  void restoreSelected() {}
  bool _obsecurePassword = true;
  bool _passwordVerified = true;
  bool _noobie = false;
  double _introPageIndex = 0;

  // Future<bool> authenticateFingerPrint() async {
  //   // verify user using in-app password or cellphone fingerprint
  //   LocalAuthentication localAuth = LocalAuthentication();
  //   try{
  //     return await localAuth.authenticate(localizedReason: 'Use your fingerprint to login', biometricOnly: true,);
  //   } catch (e){
  //     print(e);
  //     return false;
  //   }

  // }

  Widget home(BuildContext context) => WillPopScope(
      onWillPop: () async {
        if (!isSelecting) return true;
        unSelectAll();
        setState(() {
          isSelecting = false;
        });
        return false;
      },
      child: Scaffold(
        appBar: (isSelecting)
            ? AppBar( 
                leading: IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.maybePop(context);
                  },
                ),
                title: Text('${getSelectionCount()} selected'),
                actions: [
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                                title: Text('Warning'),
                                content: Text(
                                    'Are you sure you want to delete these ${getSelectionCount()} file/s???'),
                                actions: [
                                  TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text('Cancel')),
                                  TextButton(
                                      onPressed: () {
                                        deleteSelected();
                                      },
                                      child: Text('Yes'))
                                ],
                              ));
                    },
                  ),
                  IconButton(
                      icon: Icon(Icons.restore),
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                                  title: Text('Confirm Action'),
                                  content: Text(
                                      'Do you really want to restore these ${getSelectionCount()} file/s???'),
                                  actions: [
                                    TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text('Cancel')),
                                    TextButton(
                                        onPressed: () {
                                          restoreSelected();
                                        },
                                        child: Text('Yes'))
                                  ],
                                ));
                      }),
                  IconButton(
                      icon: Icon(Icons.select_all),
                      onPressed: () {
                        if (_tabController.index == 0)
                          selectAll(MyFile.IMAGE);
                        else if (_tabController.index == 1)
                          selectAll(MyFile.VIDEO);
                        else
                          selectAll(MyFile.OTHER);
                        setState(() {});
                      })
                ],
              )
            : AppBar(
                title: TextButton(child: Text(_batteryLevel), onPressed: _getBatteryLevel),//Text('Private Gallery'),
                centerTitle: true,
              ),
        floatingActionButton: Visibility(
            visible: !isSelecting,
            child: UnicornDialer(
              orientation: UnicornOrientation.VERTICAL,
              parentButton: Icon(Icons.add),
              childButtons: [
                UnicornButton(
                  hasLabel: true,
                  labelText: "Add Image",
                  currentButton: FloatingActionButton(
                      onPressed: () {
                        FilePicker.platform
                            .pickFiles(
                                allowMultiple: true, type: FileType.image)
                            .then((value) {
                          if (value != null) {
                            print(value.paths);
                            List<File> files = [];
                            value.files.toList().forEach((element) {
                              files.add(File(element.path));
                            });
                            _fileControl
                                .encryptNews(files, MyFile.IMAGE)
                                .then((isDone) {
                              _fileControl.getAllEncrypted().then((data) {
                                setState(() {
                                  formatFileLists(data);
                                });
                              });
                            });
                          }
                        });
                      },
                      heroTag: 'addimage',
                      mini: true,
                      child: Icon(Icons.add_a_photo)),
                ),
                UnicornButton(
                  hasLabel: true,
                  labelText: "Add Video",
                  currentButton: FloatingActionButton(
                      onPressed: () {
                        FilePicker.platform
                            .pickFiles(
                                allowMultiple: true, type: FileType.video)
                            .then((value) {
                          if (value != null) {
                            List<File> files = [];
                            value.files.toList().forEach((element) {
                              files.add(File(element.path));
                            });
                            _fileControl
                                .encryptNews(files, MyFile.VIDEO)
                                .then((isDone) {
                              _fileControl.getAllEncrypted().then((data) {
                                setState(() {
                                  formatFileLists(data);
                                });
                              });
                            });
                          }
                        });
                      },
                      heroTag: 'addvideo',
                      mini: true,
                      child: Icon(Icons.video_label_rounded)),
                ),
                UnicornButton(
                  hasLabel: true,
                  labelText: "Add File",
                  currentButton: FloatingActionButton(
                      onPressed: () {
                        FilePicker.platform
                            .pickFiles(allowMultiple: true, type: FileType.any)
                            .then((value) {
                          if (value != null) {
                            List<File> files = [];
                            value.files.toList().forEach((element) {
                              files.add(File(element.path));
                            });
                            _fileControl
                                .encryptNews(files, MyFile.OTHER)
                                .then((isDone) {
                              _fileControl.getAllEncrypted().then((data) {
                                setState(() {
                                  formatFileLists(data);
                                });
                              });
                            });
                          }
                        });
                      },
                      heroTag: 'addfile',
                      mini: true,
                      child: Icon(Icons.attach_file)),
                )
              ],
            )),
        drawer: (isSelecting)
            ? null
            : Drawer(
                child: Container(
                    child: ListView(children: [
                  Image.asset('assets/images/logo.jpg',
                      scale: 1.0, height: 300),
                  Divider(),
                  ListTile(
                    title: Text('Settings'),
                    onTap: () =>
                        Navigator.popAndPushNamed(context, "/settings"),
                  ),
                  Divider(),
                  ListTile(
                    title: Text('About'),
                    onTap: () => print('hello'),
                  ),
                  Divider(),
                  ListTile(title: Text('Rate 5 Stars')),
                  Divider(),
                  ListTile(title: Text('Check for updates')),
                  Divider(),
                ])),
              ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Image Grid
            Center(
                child: (areFilesReady)
                    ? GridView.count(
                        crossAxisCount: 3,
                        children:
                            List.generate(imageSelectedList.length, (index) {
                          return (imageSelectedList[index].isThumbReady)
                              ? InkWell(
                                  onTap: () {
                                    if (isSelecting) {
                                      setState(() {
                                        imageSelectedList[index].isSelected =
                                            !imageSelectedList[index]
                                                .isSelected;
                                        if (getSelectionCount() == 0)
                                          isSelecting = false;
                                      });
                                    } else
                                      Navigator.push(context, MaterialPageRoute(
                                          builder: (BuildContext context) {
                                        return ViewFileClass(
                                            imageSelectedList,
                                            imageSelectedList.length,
                                            index,
                                            getImageAt);
                                      }));
                                  },
                                  onLongPress: () {
                                    if (!isSelecting) {
                                      setState(() {
                                        isSelecting = true;
                                        imageSelectedList[index].isSelected =
                                            true;
                                      });
                                    }
                                  },
                                  child: (imageSelectedList[index].isSelected)
                                      ? Stack(
                                          alignment:
                                              AlignmentDirectional.center,
                                          children: [
                                              Transform.scale(
                                                scale: 0.9,
                                                child: Container(
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: Colors
                                                              .transparent,
                                                          width: 1),
                                                    ),
                                                    width: 200,
                                                    height: 200,
                                                    child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(5),
                                                        child: Image.asset(
                                                          imageSelectedList[
                                                                  index]
                                                              .thumb,
                                                          fit: BoxFit.cover,
                                                          colorBlendMode:
                                                              BlendMode.clear,
                                                        ))),
                                              ),
                                              Container(
                                                width: 200,
                                                height: 200,
                                                margin: EdgeInsets.all(10),
                                                child: Icon(
                                                  Icons.check_circle,
                                                  size: 30,
                                                  color: Colors.white,
                                                ),
                                                alignment: AlignmentDirectional
                                                    .topStart,
                                              ),
                                            ])
                                      : Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.transparent, width: 3),
                                          ),
                                          width: 200,
                                          height: 200,
                                          child: Hero(
                                              tag: 'image$index',
                                              child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                  child: Image.asset(
                                                    imageSelectedList[index]
                                                        .thumb,
                                                    fit: BoxFit.cover,
                                                    colorBlendMode:
                                                        BlendMode.clear,
                                                  )))),
                                )
                              : Center(child: CircularProgressIndicator());
                          //);
                        }))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Text('Loading Files'),
                            CircularProgressIndicator(),
                          ])),
            Center(
              child: (areFilesReady)
                  ? GridView.count(
                      crossAxisCount: 3,
                      crossAxisSpacing: 1,
                      children:
                          List.generate(videoSelectedList.length, (index) {
                        return (areThumbsReady)
                            ? InkWell(
                                child: (videoSelectedList[index].isSelected)
                                    ? Stack(
                                        alignment: AlignmentDirectional.center,
                                        children: [
                                            Transform.scale(
                                              scale: 0.9,
                                              child: Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color:
                                                            Colors.transparent,
                                                        width: 1),
                                                  ),
                                                  width: 200,
                                                  height: 200,
                                                  child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5),
                                                      child: Hero(
                                                        tag: 'video$index',
                                                        child:Image.asset(
                                                        videoSelectedList[index].thumb,
                                                        fit: BoxFit.cover,
                                                        colorBlendMode:
                                                            BlendMode.clear,
                                                        )
                                                      ))),
                                            ),
                                            Container(
                                              width: 200,
                                              height: 200,
                                              margin: EdgeInsets.all(10),
                                              child: Icon(
                                                Icons.check_circle,
                                                size: 30,
                                                color: Colors.white,
                                              ),
                                              alignment:
                                                  AlignmentDirectional.topStart,
                                            ),
                                          ])
                                    : Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.transparent, width: 3),
                                        ),
                                        width: 200,
                                        height: 200,
                                        child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                            child: Hero(
                                              tag: 'video$index',
                                              child:Image.asset(
                                              videoSelectedList[index].thumb,
                                              fit: BoxFit.cover,
                                              colorBlendMode: BlendMode.clear,
                                              )
                                            ))),
                                onTap: () {
                                  if (isSelecting) {
                                    setState(() {
                                      videoSelectedList[index].isSelected =
                                          !videoSelectedList[index].isSelected;
                                      if (getSelectionCount() == 0)
                                        isSelecting = false;
                                    });
                                  } else
                                    Navigator.push(context, MaterialPageRoute(
                                        builder: (BuildContext context) {
                                      return ViewFileClass(
                                          videoSelectedList,
                                          videoSelectedList.length,
                                          index,
                                          getVideoAt);
                                    }));
                                },
                                onLongPress: () {
                                  if (!isSelecting) {
                                    setState(() {
                                      isSelecting = true;
                                      videoSelectedList[index].isSelected =
                                          true;
                                    });
                                  }
                                },
                              )
                            : Center(child: CircularProgressIndicator());
                      }))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                          Text('Loading Files'),
                          CircularProgressIndicator(),
                        ]),
            ),
            Center(
                child: (areFilesReady)
                    ? ListView.builder(
                        itemCount: otherSelectedList.length,
                        itemBuilder: (context, i) => ListTile(
                              leading: Text("$i"),
                              subtitle: Text('.txt File'),
                              title: Text('File $i'),
                              trailing: (otherSelectedList[i].isSelected)
                                  ? Icon(Icons.check_circle)
                                  : null,
                              onTap: () {
                                if (isSelecting) {
                                  setState(() {
                                    otherSelectedList[i].isSelected =
                                        !videoSelectedList[i].isSelected;
                                    if (getSelectionCount() == 0)
                                      isSelecting = false;
                                  });
                                } else
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          SimpleDialog(
                                            title: Text('File Name'),
                                            elevation: 10,
                                            children: [
                                              ListTile(
                                                leading: Icon(Icons.restore),
                                                title: Text('Restore File'),
                                                onTap: () {},
                                              ),
                                              ListTile(
                                                leading: Icon(Icons.details),
                                                title: Text('Details'),
                                                onTap: () {},
                                              ),
                                              ListTile(
                                                leading: Icon(Icons.delete),
                                                title: Text('Delete File'),
                                                onTap: () {},
                                              ),
                                              SimpleDialogOption(
                                                child: TextButton(
                                                  child: Text('OK'),
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                ),
                                              ),
                                            ],
                                          ));
                              },
                              onLongPress: () {
                                if (!isSelecting) {
                                  setState(() {
                                    isSelecting = true;
                                    otherSelectedList[i].isSelected = true;
                                  });
                                }
                              },
                            ))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Loading Files'),
                          CircularProgressIndicator()
                        ],
                      ))
          ],
        ),
        bottomNavigationBar: Material(
            //color: Colors.transparent,
            child: TabBar(
          tabs: [
            Tab(
                icon: Icon(
                  Icons.image,
                  //color: Colors.black,
                ),
                child: Text(
                  'Images',
                  // style: TextStyle(color: Colors.black),
                )),
            Tab(
                icon: Icon(
                  Icons.video_label,
                  // color: Colors.black
                ),
                child: Text(
                  'Videos',
                  //style: TextStyle(color: Colors.black)
                )),
            Tab(
                icon: Icon(
                  Icons.file_present,
                  //color: Colors.black
                ),
                child: Text(
                  'Files',
                  //style: TextStyle(color: Colors.black)
                ))
          ],
          controller: _tabController,
        )),
      ));

  Widget settings(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Column(
        children: [
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Theme'),
            trailing: DropdownButton(
              value: theme,
              onChanged: (newValue) {
                setState(() {
                  theme = newValue;
                });
              },
              items: [
                DropdownMenuItem(
                  child: Text('System'),
                  value: 0,
                ),
                DropdownMenuItem(child: Text('Light'), value: 1),
                DropdownMenuItem(child: Text('Dark'), value: 2)
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Change password'),
            onTap: () {
              showDialog(
                  context: context,
                  builder: (context) => Dialog(
                        child: Container(
                          height: 350,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Card(
                                child: Text(
                                  'Change your password',
                                  style: TextStyle(fontSize: 20),
                                ),
                              ),
                              ListTile(
                                leading: Text('Old Password'),
                                title: TextField(),
                              ),
                              ListTile(
                                leading: Text('New Password'),
                                title: TextField(),
                              ),
                              ListTile(
                                leading: Text('Confirm Password'),
                                title: TextField(),
                              ),
                              TextButton(
                                child: Text('Cancel'),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                              TextButton(
                                child: Text('Confirm Change'),
                                onPressed: () {},
                              )
                            ],
                          ),
                        ),
                      ));
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Use FingerPrint'),
            trailing: Switch(
              value: true,
              onChanged: (newValue) {},
            ),
          )
        ],
      ));
  Widget intro(BuildContext context) => Scaffold(
          body: Container(
        child: Stack(alignment: AlignmentDirectional.bottomCenter, children: [
          PageView(
            onPageChanged: (index) => setState(() {
              _introPageIndex = index / 1.0;
            }),
            controller: _introPageController,
            children: [
              Container(
                width: 100,
                child: Center(
                    child: Text(
                  'Hello there!',
                  style: TextStyle(
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                )),
              ),
              Container(
                  width: 100,
                  child: Center(
                      child: Text(
                    'Welcome to Private Gallery!\nThis app will help you hide your private photos, videos and any other files from unwanted access!',
                    style: TextStyle(fontSize: 24),
                    textAlign: TextAlign.center,
                  ))),
              Container(
                  width: 100,
                  child: Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                        Text(
                            'First Let\'s setup the password you will be using for this app!',
                            style: TextStyle(fontSize: 24),
                            textAlign: TextAlign.center),
                        Divider(
                          thickness: 0,
                        ),
                        SizedBox(
                            width: 200,
                            child: TextField(
                              onChanged: (value) {
                                setState(() {
                                  _tempPassword1 = value;
                                });
                              },
                              decoration: InputDecoration(
                                  labelText: 'Input Password',
                                  border: InputBorder.none),
                            )),
                        SizedBox(
                            width: 200,
                            child: TextField(
                                focusNode: passwordRepeatNode,
                                onChanged: (value) {
                                  if (value != _tempPassword1) {
                                    passwordNotMatched = true;
                                  }
                                  setState(() {
                                    _tempPassword2 = value;
                                  });
                                },
                                decoration: InputDecoration(
                                    errorText: (passwordNotMatched)
                                        ? 'Passwords don\'t match'
                                        : null,
                                    labelText: 'confirm password',
                                    border: InputBorder.none))),
                        Divider(
                          thickness: 0,
                        ),
                        ElevatedButton(
                            onPressed: () {
                              // task: setup password
                              if (!passwordNotMatched) {
                                _preferences.setString(
                                    'password', '$_tempPassword1');
                                Navigator.popAndPushNamed(context, '/home');
                              } else
                                passwordRepeatNode.requestFocus();
                            },
                            child: Text('Finish Setup'))
                      ])))
            ],
          ),
          DotsIndicator(
            dotsCount: 3,
            decorator: DotsDecorator(
              activeColor: Colors.blue,
              color: Colors.grey,
            ),
            onTap: (index) {
              setState(() {
                _introPageController.animateToPage((index.toInt()),
                    curve: Curves.easeIn,
                    duration: Duration(milliseconds: 500));
              });
            },
            position: _introPageIndex,
          ),
        ]),
      ));

  Widget identification(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Card(
                elevation: 2.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Card(
                      child: SizedBox(
                          height: 200,
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'May I ask your ID, Please?',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 24),
                                ),
                              ])),
                      elevation: 2,
                    ),
                    SizedBox(
                        width: 200,
                        child: TextField(
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          onSubmitted: (value) {
                            // route to main page
                          },
                          obscureText: _obsecurePassword,
                          decoration: InputDecoration(
                              prefixIcon: Icon(Icons.security_rounded),
                              suffixIcon: IconButton(
                                tooltip: (_obsecurePassword)
                                    ? 'show password'
                                    : 'hide password',
                                icon: Icon(Icons.remove_red_eye,
                                    color: (_obsecurePassword)
                                        ? Colors.grey
                                        : Colors.blue),
                                onPressed: () {
                                  setState(() {
                                    _obsecurePassword = !_obsecurePassword;
                                  });
                                },
                              ),
                              labelText: 'Password',
                              border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10.0)))),
                        )),
                    Card(
                      elevation: 2.0,
                      child: Text(
                        'Fingerprint is okay too!',
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    Card(
                        key: Key('fingerprint'),
                        elevation: 2,
                        child: Image.asset(
                          'assets/images/fingerprint.png',
                          width: 300,
                        ))
                  ],
                ))));
  }

  Widget viewImage(BuildContext context, Image image) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Image Name'),
        ),
        body: Center(
          child: Image.asset(
            'assets/images/logo.jpg',
            fit: BoxFit.fill,
            isAntiAlias: true,
          ),
        ));
  }

  Widget initialRoute(BuildContext context) {
    return (_noobie)
        ? intro(context)
        : (_passwordVerified)
            ? home(context)
            : identification(context);
  }

  void setPreferences() {
    if (_preferences.getKeys().length == 0) {
      print('no preferences found');
      // set default preferences
      // setState((){
      //   _noobie = true;
      // });
      return;
    }
    // _preferences.clear();
    // return;
    this.theme = _preferences.getInt('theme');
    this.isFingerPrintSet = _preferences.getBool('isfingerprintset');
    this._password = _preferences.getString('password');
  }

  void formatFileLists(Map<String, List<MyFile>> data) {
    imageSelectedList.clear();
    videoSelectedList.clear();
    otherSelectedList.clear();
    for (MyFile myFile in data['images'])
      this.imageSelectedList.add(MyFileSelectionItem(myFile, () {
            setState(() {});
          }));
    for (MyFile myFile in data['videos'])
      this.videoSelectedList.add(MyFileSelectionItem(myFile, () {
            setState(() {});
          }));
    for (MyFile myFile in data['others'])
      this.otherSelectedList.add(MyFileSelectionItem(myFile, () {
            setState(() {});
          }));
  }

  @override
  void initState() {
    super.initState();
    this._tabController = TabController(length: 3, vsync: this);
    this._fileControl = FileControl();
    this.imageSelectedList = [];
    this.videoSelectedList = [];
    this.otherSelectedList = [];
    _fileControl.getSharedPreferences().then((value) {
      _preferences = value;
      setPreferences();
      setState(() {
        isPreferencesReady = true;
      });
    });
    _fileControl.getAllEncrypted().then((data) {
      formatFileLists(data);
      setState(() {
        areFilesReady = true;
      });
    });
    _fileControl.getThumbs().then((data) {
      this._thumbs = data;
      setState(() {
        areThumbsReady = true;
      });
    });
  }

  MyFileSelectionItem getImageAt(int index) {
    return imageSelectedList[index];
  }

  MyFileSelectionItem getVideoAt(int index) {
    return videoSelectedList[index];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Private Gallery',
      theme: ThemeData(
          primaryColor: Colors.white,
          pageTransitionsTheme: PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                TargetPlatform.android: ZoomPageTransitionsBuilder()
              })),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      themeMode: (theme == 2)
          ? ThemeMode.dark
          : (theme == 1)
              ? ThemeMode.light
              : ThemeMode.system,
      initialRoute: '/home',
      routes: {
        '/': (context) => initialRoute(context),
        '/settings': (context) => settings(context),
        '/intro': (context) => intro(context),
        '/identification': (context) => identification(context),
        '/home': (context) => home(context)
      },
    );
  }
}

class ViewFileClass extends StatefulWidget {
  final List<MyFileSelectionItem> files;
  final int tabLength, initialIndex;
  final Function request;
  ViewFileClass(this.files, this.tabLength, this.initialIndex, this.request);
  _ViewFileClassState createState() => _ViewFileClassState(
      this.files, this.tabLength, this.initialIndex, this.request);
}

class _ViewFileClassState extends State<ViewFileClass> {
  bool isSheetOpen = false;
  bool playerIconVisible = true;
  String viewType;
  int preIndex = 0;
  PageController _pageController;
  File temp;
  String tempType;
  int tabLength, initialIndex;
  List<MyFileSelectionItem> files;
  List<Widget> pages;
  Function request;
  _ViewFileClassState(
      this.files, this.tabLength, this.initialIndex, this.request)
      : viewType = files[0].myFile.type;
  @override
  void initState() {
    super.initState();
    print("filePath from ViewFile call was : ${files[initialIndex].myFile.path}");
    _pageController = PageController(initialPage: initialIndex);
    pages = List.generate(tabLength, (index) => Center(child: CircularProgressIndicator()));
    getTemps().then((value){
      setState(() {
        if(initialIndex == 0){
          pages[initialIndex] = getViewOf(value[0]);
          pages[initialIndex + 1] = getViewOf(value[1]);
        }
        else if(initialIndex == tabLength -1){
          pages[initialIndex-1] = getViewOf(value[0]);
          pages[initialIndex] = getViewOf(value[1]);
        }
        else {
        pages[initialIndex-1] = getViewOf(value[0]);
        pages[initialIndex] = getViewOf(value[1]);
        pages[initialIndex+1] = getViewOf(value[2]);
        }
      });
    });
  }
  Widget getViewOf(File x){
    if(viewType == MyFile.IMAGE)
      return Hero(
            tag: 'image$initialIndex',
            child: PhotoView(imageProvider: FileImage(x)));
    else return Hero(
          tag: 'video$initialIndex',
          child: VideoPlayerPage(x)
        );
  }
  Future<List<File>> getTemps() async {
    if(initialIndex == 0){
       File temp = await files[initialIndex].myFile.getTemp();
      File tempmax = await files[initialIndex+1].myFile.getTemp();
      return [temp,tempmax];
    }
    else if(initialIndex == tabLength - 1){
      File tempmin = await files[initialIndex-1].myFile.getTemp();
      File temp = await files[initialIndex].myFile.getTemp();
      return [tempmin,temp];
    }
    File tempmin = await files[initialIndex-1].myFile.getTemp();
    File temp = await files[initialIndex].myFile.getTemp();
    File tempmax = await files[initialIndex+1].myFile.getTemp();
    return [tempmin,temp,tempmax];
  }
  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();

  }

  // String parseDuration(Duration duration) {
  //   int hour = duration.inHours % 24;
  //   int mint = duration.inMinutes % 60;
  //   int secd = duration.inSeconds % 60;
  //   String hr = (hour > 10) ? "$hour:" : "0$hour:";
  //   String min = (mint > 10) ? "$mint:" : "0$mint:";
  //   String sec = (secd > 10) ? "$secd" : "0$secd";
  //   return hr + min + sec;
  // }

  // Widget videoPlayerPage(VideoPlayerController tempController) {
  //   return Container(
  //       color: Colors.transparent,
  //       child: Center(
  //           child: (tempController.value.isInitialized)
  //               ? Stack(
  //                   alignment: AlignmentDirectional.bottomCenter,
  //                   children: [
  //                     Stack(
  //                       alignment: AlignmentDirectional.center,
  //                       children: [
  //                         InkWell(
  //                           child: AspectRatio(
  //                               aspectRatio: tempController.value.aspectRatio,
  //                               child: VideoPlayer(tempController)),
  //                           onTap: () {
  //                             setState(() {
  //                               playerIconVisible = !playerIconVisible;
  //                               isSheetOpen = playerIconVisible;
  //                             });
  //                           },
  //                         ),
  //                         Visibility(
  //                           visible: playerIconVisible,
  //                           child: Container(
  //                               decoration: BoxDecoration(
  //                                   borderRadius: BorderRadius.circular(90),
  //                                   color: Color.fromARGB(50, 0, 0, 0)),
  //                               child: IconButton(
  //                                 icon: Icon((tempController.value.isPlaying)
  //                                     ? Icons.pause
  //                                     : Icons.play_arrow),
  //                                 onPressed: () {
  //                                   if (tempController.value.isPlaying)
  //                                     tempController.pause();
  //                                   else
  //                                     tempController.play();
  //                                 },
  //                               )),
  //                         )
  //                       ],
  //                     ),
  //                     Visibility(
  //                         visible: playerIconVisible,
  //                         child: Row(children: [
  //                           Text(parseDuration(tempController.value.position)),
  //                           Expanded(
  //                               child: VideoProgressIndicator(
  //                             tempController,
  //                             allowScrubbing: true,
  //                           )),
  //                           Text(parseDuration(tempController.value.duration))
  //                         ]))
  //                   ],
  //                 )
  //               : CircularProgressIndicator()));
  // }

  // Widget getViewAt(int index) {
  //   // request(index).myFile.getTemp().then((file){
  //   //     setState((){
  //   //       temp = file;
  //   //       tempType = request(index).myFile.type;
  //   //     });
  //   // });
  //   // final tempFile = request(index).myFile.getTemp();
  //   // if(temp == null || tempType != request(index).myFile.type)
  //   //   return Center(
  //   //     child: CircularProgressIndicator()
  //   //   );
  //   if (index == initialIndex ||
  //       index == initialIndex - 1 ||
  //       index == initialIndex + 1) {
  //     // immidiate right or left of the view
  //     if (viewType == MyFile.IMAGE )
  //       return Hero(
  //           tag: 'image$initialIndex',
  //           child: PhotoView(imageProvider: FileImage(tempList[index])));
  //     else {
  //       return Hero(
  //         tag: 'video$initialIndex',
  //         child: VideoPlayerPage(tempList[index])
  //       );
  //     }
  //   }
  //   return Text('this never shows');
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      primary: true,
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
          child: Visibility(
            visible: isSheetOpen,
            child: AppBar(
              iconTheme: ThemeData.dark().iconTheme,
              title:
                  Text(files[initialIndex].myFile.name, style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.transparent,
              centerTitle: true,
              elevation: 0,
            ),
          ),
          preferredSize: Size.copy(AppBar().preferredSize)),
      body: Container(
          color: Colors.transparent,
          child: InkWell(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Stack(
              alignment: AlignmentDirectional.bottomCenter,
              children: [
                PageView(
                    controller: this._pageController,
                    onPageChanged: (index) {
                      if(index < (tabLength-1) && index > 0)
                        if(pages[index -(initialIndex - index)] is Center ){
                          final initial = initialIndex;
                          files[index -(initial - index)].myFile.getTemp().then((value) {
                            setState((){
                            pages[index -(initial - index)] = getViewOf(value);
                            });
                          });
                        }
                        initialIndex = index;
                    },
                    children: List.from(pages)
                    // List.generate(
                      //  this.tabLength, (index) => Text('$index'))//getViewAt(index))
              
                    ),
                Visibility(
                    visible: isSheetOpen,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                                style: ButtonStyle(
                                    foregroundColor:
                                        MaterialStateProperty.resolveWith(
                                            (states) => Colors.white)),
                                onPressed: () {},
                                child: Column(
                                  children: [
                                    Icon(Icons.restore),
                                    Text(
                                      'Restore',
                                    )
                                  ],
                                ))
                          ],
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                                style: ButtonStyle(
                                    foregroundColor:
                                        MaterialStateProperty.resolveWith(
                                            (states) => Colors.white)),
                                onPressed: () {},
                                child: Column(
                                  children: [
                                    Icon(Icons.delete),
                                    Text('Delete')
                                  ],
                                ))
                          ],
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                                style: ButtonStyle(
                                    foregroundColor:
                                        MaterialStateProperty.resolveWith(
                                            (states) => Colors.white)),
                                onPressed: () {},
                                child: Column(
                                  children: [
                                    Icon(Icons.details),
                                    Text('Details')
                                  ],
                                ))
                          ],
                        )
                      ],
                    ))
              ],
            ),
            onTap: () {
              setState(() {
                isSheetOpen = !isSheetOpen;
              });
            },
          )),
    );
  }
}
class VideoPlayerPage extends StatefulWidget{
  final File file;
  VideoPlayerPage(this.file);
  VideoPlayerState createState() => VideoPlayerState(this.file);
}
class VideoPlayerState extends State<VideoPlayerPage>{
  final File file;
  VideoPlayerController tempController;
  bool playerIconVisible = true;
  bool isReady = false;
  VideoPlayerState(this.file);
  @override
  void initState(){
    super.initState();
    tempController = VideoPlayerController.file(file)
      ..addListener(() {
        setState((){});
      })
      ..setLooping(true)
      ..initialize();
  }
  String parseDuration(Duration duration) {
    int hour = duration.inHours % 24;
    int mint = duration.inMinutes % 60;
    int secd = duration.inSeconds % 60;
    String hr = (hour > 10) ? "$hour:" : "0$hour:";
    String min = (mint > 10) ? "$mint:" : "0$mint:";
    String sec = (secd > 10) ? "$secd" : "0$secd";
    return hr + min + sec;
  }
  @override
  void dispose(){
    tempController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context){
    return WillPopScope(
      onWillPop: () async {
        tempController.pause();
        return true;
      },
      child:Container(
        color: Colors.transparent,
        child: Center(
            child: (tempController.value.isInitialized)
                ? Stack(
                    alignment: AlignmentDirectional.bottomCenter,
                    children: [
                      Stack(
                        alignment: AlignmentDirectional.center,
                        children: [
                          InkWell(
                            child: AspectRatio(
                                aspectRatio: tempController.value.aspectRatio,
                                child: VideoPlayer(tempController)),
                            onTap: () {
                              setState(() {
                                playerIconVisible = !playerIconVisible;
                              });
                            },
                          ),
                          Visibility(
                            visible: playerIconVisible,
                            child: Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(90),
                                    color: Color.fromARGB(50, 0, 0, 0)),
                                child: IconButton(
                                  icon: Icon((tempController.value.isPlaying)
                                      ? Icons.pause
                                      : Icons.play_arrow),
                                  onPressed: () {
                                    if (tempController.value.isPlaying)
                                      tempController.pause();
                                    else
                                      tempController.play();
                                  },
                                )),
                          )
                        ],
                      ),
                      Visibility(
                          visible: playerIconVisible,
                          child: Row(children: [
                            Text(parseDuration(tempController.value.position)),
                            Expanded(
                                child: VideoProgressIndicator(
                              tempController,
                              allowScrubbing: true,
                            )),
                            Text(parseDuration(tempController.value.duration))
                          ]))
                    ],
                  )
                : Center(
                  child:CircularProgressIndicator())
                  ))
    );
  }

}