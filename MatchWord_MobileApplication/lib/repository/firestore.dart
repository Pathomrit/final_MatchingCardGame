import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:match_word/repository/model.dart';
import 'dart:io' as io;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

const _collectionAppData = "AppData";
const _collectionRequestData = "RequestData";

Future<List<AppData>> getAppData(String? level) async {
  List<AppData> list = [];
  CollectionReference appData =  FirebaseFirestore.instance.collection(_collectionAppData);
  QuerySnapshot querySnapshot = await appData.get();

  var data = querySnapshot.docs.map((doc) => AppData.fromMap(doc.data() as Map<String, dynamic>)).toList();
  for(var data in data) {
    await _saveImage(data.image);
    await _saveImage(data.wordImage);
    if (level == null || data.level == level) {
      list.add(data);
    }
  }
  return list;
}

Future<void> loadAssets() async {
  CollectionReference appData =  FirebaseFirestore.instance.collection(_collectionAppData);
  QuerySnapshot querySnapshot = await appData.get();

  var data = querySnapshot.docs.map((doc) => AppData.fromMap(doc.data() as Map<String, dynamic>)).toList();
  for(var data in data) {
    await _saveImage(data.image);
    await _saveImage(data.wordImage);
  }
}

Future<void> _saveImage(String path) async {
  final dir = await getApplicationDocumentsDirectory();
  var file = io.File("${dir.path}/assets/AppData/$path");
  var isExists = await file.exists();
  if (isExists) {
    return;
  }
  final storage = FirebaseStorage.instance.ref();
  final url = await storage.child(path).getDownloadURL();
  try {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      await file.create(recursive: true);
      await file.writeAsBytes(res.bodyBytes);
    }
  } catch (e) {
    print(e);
  }
}