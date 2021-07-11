import 'dart:convert';
import "dart:io";
import 'dart:typed_data';

//import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class FileControl {
  Directory _defaultDirectory;
  List<MyFile> _images;
  List<MyFile> _videos;
  List<MyFile> _others;
  SharedPreferences _preferences;
  Map<String,dynamic> _objectList;
  FileControl() {
    init();
  }
  void init() async {
    _images = [];
    _videos = [];
    _others = [];
    this._defaultDirectory = await getApplicationDocumentsDirectory();
    
    //create ObjectList and extract images
  }
  Future<SharedPreferences> getSharedPreferences() async {
    if(_preferences ==null)
      _preferences = await SharedPreferences.getInstance();
    return _preferences;
  }
  Directory getApplicationDirectory() => _defaultDirectory;

  // Future<MyFile> getAFilePath({FileType type: FileType.any}) async {
  //   return FilePicker.platform.pickFiles(type: type).then((result) =>
  //       (result == null) ? null : MyFile(File(result.files.single.path), type));
  // }

  // Future<MyFile> getAnImagePath() async => getAFilePath(type: FileType.image);
  // Future<MyFile> getAVideoPath() async => getAFilePath(type: FileType.video);

  // Future<List<MyFile>> getFilesPaths({FileType type: FileType.any}) async =>
  //     FilePicker.platform
  //         .pickFiles(type: type, allowMultiple: true)
  //         .then((result) {
  //       List<MyFile> fileList = [];
  //       result.files.forEach((element) {
  //         fileList.add(MyFile(File(element.path), type));
  //       });
  //       return fileList;
  //     });
  // Future<List<MyFile>> getImagesPath() async =>
  //     getFilesPaths(type: FileType.image);
  // Future<List<MyFile>> getVideosPath() async =>
  //     getFilesPaths(type: FileType.video);
  String getParentOf(String type) => getApplicationDirectory().path+((type == MyFile.IMAGE)
        ? '/images'
        : (type == MyFile.VIDEO)
            ? '/videos'
            : '/others');
            // Partially Done
  Future<Map<String,List<MyFile>>> getAllEncrypted() async {
    // return all from $objectList with type of $type
    await getSharedPreferences();
    if(_objectList==null) loadObjectList();
    // String areYou = await Future<String>.delayed(Duration(seconds: 5),(){return 'hi';});
    // List<MyFile> images =[],videos=[],others=[];
    // for(int i = 0;i<50;i++) images.add(MyFile());
    // for(int i = 0;i<34;i++) videos.add(MyFile());
    // for(int i = 0;i<20;i++) others.add(MyFile());
    // this._images = images;
    // this._videos = videos;
    // this._others = others;
    return {'images':this._images,'videos':this._videos,'others':this._others};
  }
  void loadObjectList(){
    if(_preferences.getKeys().length==0){
      _objectList = {};
      _preferences.setString('objectList', JsonEncoder().convert(_objectList));
    }
    else{
      _objectList = JsonDecoder().convert(_preferences.getString('objectList')) as Map<String,dynamic>;//.map((key, value) => MapEntry(key, MyFile.fromJson(value)));
    }
    List<MyFile> temp=[];
    _objectList.forEach((key, value) {temp.add(MyFile.fromJson(value));});
    for(int i = 0;i<_objectList.length;i++){
      if(temp[i].isImage())
        _images.add(temp[i]);
      else if(temp[i].isVideo())
        _videos.add(temp[i]);
      else _others.add(temp[i]);
    }
  }
  void updateObjectList(MyFile myFile){
    _objectList.addAll({
      myFile.id : myFile.toJson()
    });
    _preferences.setString('objectList', JsonEncoder().convert(_objectList));
    if(myFile.isImage())
      _images.add(myFile);
    else if(myFile.isVideo())
      _videos.add(myFile);
    else _others.add(myFile);
  }
    // Partially Done
  Future<bool> encryptNew(File x,String type) async {
    MyFile encrypted = MyFile.encryptNew(x,type,getParentOf(type));
    // save $encrypted on objectList;
    // _objectList.addAll({encrypted.id:encrypted.toJson()});
    // _preferences.setString('objectList', JsonEncoder().convert(_objectList));
    updateObjectList(encrypted);
    return true;
  }
    // Partially Done
  Future<bool> encryptNews(List<File> files,String type) async{
    for(File file in files){
      MyFile encrypted = MyFile.encryptNew(file, type, getParentOf(type));
      updateObjectList(encrypted);
    }
    return true;
  }
  Future<Map<String,List</*File*/String>>> getThumbs() async{
    // get all thumbnails as a Map{'images':List<File>, 'videos: List<File>}
    List</*File*/String> imageThumbs = [],videoThumbs=[];
    for (int i = 0;i<50;i++){
      imageThumbs.add('assets/images/logo.jpg');
      if(i<34)
        videoThumbs.add('assets/images/logo.jpg');
    }
    return {'images':imageThumbs,'videos':videoThumbs};
  }
  Future<bool> decryptOld(MyFile file) async {
    return file.decrypt();
  }
  Future<bool> decryptOlds(List<MyFile> files) async {
    bool success = false;
    for (MyFile file in files)
      success = success && file.decrypt();
    return success;
  }
}

class MyFile {
  static const IMAGE = 'image';
  static const VIDEO = 'video';
  static const OTHER = 'other';
  static String extensionOf(File file){
    return file.path.substring(file.path.lastIndexOf('.')+1);
  }
  String _path;
  String _thumbPath;
  String _id;
  String _type;
  Uint8List _rawBytes;
  String _name;
  String _lastPath; // from where it was encrypted
  File _file; // actual encrypted/to_be_encrypted file
  MyFile.encryptNew(File plainFile,this._type,String parent){
    _name = plainFile.path.substring(plainFile.path.lastIndexOf('/') + 1);
    _id = DateTime.now().toString() + '@' + _name;
    // encrypt $plainFile and create $this._file
    Uint8List plainBytes = plainFile.readAsBytesSync();
    List<int> byteList = [];
    plainBytes.forEach((byte) {
        byteList.add(byte + 20);
     });
    Uint8List encryptedBytes = Uint8List.fromList(byteList);
    this._file = File('$parent/$_id');
    if(!this._file.parent.existsSync()) this._file.parent.createSync();
    this._file.createSync();
    this._file.writeAsBytesSync(encryptedBytes);
    this._path = this._file.path;
    this._lastPath = plainFile.path;
    this._thumbPath = ''; // thumb here
    try{
      print('deleting file ${plainFile.uri.toFilePath()}');
      plainFile.deleteSync(recursive: true);
    } catch(e){
      print(e);
    }
  }
  String  get type => _type;
  String get path => _path;
  File get file => _file;
  String get name => _name;
  String get lastPath => _lastPath;
  String get id => _id;
  String get thumbPath => _thumbPath;

  bool isImage() => _type == MyFile.IMAGE;
  bool isVideo() => _type == MyFile.VIDEO;
  bool isOther() => _type == MyFile.OTHER;
  Future<File> getTemp() async { // a temporary in-application location of decrypted type of $this._file
    print('request temp of: $_path');
    List<int> tempList = [];
    Uint8List bytes = await _file.readAsBytes();
    bytes.forEach((byte) {tempList.add(byte - 20);});
    File temp = File('${_file.parent.path}/temp$_name.${extensionOf(_file)}');
    if( await temp.exists()) 
      return temp;
    try{
    await temp.create();
    } catch (e){
      print(e);
    }
    await temp.writeAsBytes(Uint8List.fromList(tempList));
    return temp;
  }
  Uint8List _getBytes(){
    return (_rawBytes == null)? _rawBytes = _file.readAsBytesSync():_rawBytes;
  }
  Future<String> getThumb() async { // a permanent in-application location of low-quality thumbnail of $this._file
   return 'assets/images/logo.jpg'; // return from thumb package
  }
  bool decrypt(){
    Uint8List encryptedBytes = _getBytes();
    List<int> byteList = [];
    encryptedBytes.forEach((byte) {
      byteList.add(byte - 20);
     });
    File plainFile = File(lastPath);
    if(!plainFile.parent.existsSync()) plainFile.parent.createSync(recursive:true);
    plainFile.createSync();
    plainFile.writeAsBytesSync(Uint8List.fromList(byteList));
    delete();
    return true;
  }
  void delete(){
    this._file.delete();
  }
  static Map<String, MyFile> mapToMyFile(Map<String,dynamic> jsonList){
    Map<String,MyFile> mapList ={};
    jsonList.forEach((key, value) {
      mapList.addAll({key:MyFile.fromJson(value)});
    });
    return mapList;
  }
  Map<String, dynamic> toJson(){
    return {
      'path':_path,
      'type':_type,
      'id':_id,
      'rawbytes':_rawBytes,
      'name':_name,
      'lastpath':_lastPath,
      'thumbpath':_thumbPath
    };
  }
  MyFile.fromJson(Map<String,dynamic> json){
    this._path = json['path'];
    this._file = File(_path);
    this._type = json['type'];
    this._id = json['id'];
    this._rawBytes = json['rawbytes'];
    this._name = json['name'];
    this._lastPath = json['lastpath'];
    this._thumbPath = json['thumbpath'];
  }
}
