import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:gal/gal.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

enum ImageSourceType { gallery, camera }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _image;
  var imagePicker;
  var type;

  @override
  void initState() {
    super.initState();
    imagePicker = new ImagePicker();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal[300],
        centerTitle: true,
        title: Text(
          'Penghapus Background Gambar',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(color: Colors.grey),
                child: _image != null
                    ? Image.file(
                        _image,
                        width: 200.0,
                        height: 200.0,
                        fit: BoxFit.fitHeight,
                      )
                    : Container(
                        decoration: BoxDecoration(color: Colors.grey),
                        width: 200,
                        height: 200,
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.grey[800],
                        ),
                      ),
              ),
              onTap: () {
                showModalBottomSheet(
                  isDismissible: false,
                  context: context,
                  builder: (context) {
                    return Wrap(
                      children: [
                        ListTile(
                          onTap: () async {
                            XFile image = await imagePicker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 50,
                              preferredCameraDevice: CameraDevice.rear,
                            );
                            setState(() {
                              _image = File(image.path);
                            });
                            Navigator.pop(context);
                          },
                          leading: Icon(Icons.filter_rounded),
                          title: Text('Pick image from galery'),
                        ),
                        ListTile(
                          onTap: () async {
                            XFile image = await imagePicker.pickImage(
                              source: ImageSource.camera,
                              imageQuality: 50,
                              preferredCameraDevice: CameraDevice.front,
                            );
                            setState(() {
                              _image = File(image.path);
                            });
                            Navigator.pop(context);
                          },
                          leading: Icon(Icons.camera_alt_outlined),
                          title: Text('Pick image from camera'),
                        ),
                        ListTile(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          leading: Icon(Icons.cancel_outlined),
                          title: Text('Cancel'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            SizedBox(
              height: 45,
            ),
            ElevatedButton(
              onPressed: () async {
                if (_image == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.all(15),
                      content: Text('Mohon Masukkan Gambar!'),
                      backgroundColor: (Colors.black),
                      action: SnackBarAction(
                        label: 'Mengerti',
                        onPressed: () {},
                      ),
                    ),
                  );
                } else {
                  var request = http.MultipartRequest(
                      'POST', Uri.parse('https://api.remove.bg/v1.0/removebg'));
                  request.headers['X-Api-Key'] = 'SOMETHING';
                  request.files.add(
                    http.MultipartFile.fromBytes(
                      'image_file',
                      _image.readAsBytesSync(),
                      filename: _image.path.split("/").last,
                    ),
                  );
                  request.fields['size'] = 'auto';

                  final streamedResponse = await request.send();
                  final response =
                      await http.Response.fromStream(streamedResponse);
                  // print(response.bodyBytes);
                  if (response.statusCode == 200) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text("Gambar Hasil"),
                          content: Image.memory(response.bodyBytes),
                          actions: [
                            ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStatePropertyAll(Colors.green),
                              ),
                              onPressed: () async {
                                await Gal.putImageBytes(response.bodyBytes,
                                    name: 'background-remover-image');
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    margin: EdgeInsets.all(15),
                                    content: Text('Gambar berhasil disimpan!'),
                                    backgroundColor: (Colors.black),
                                    duration: Duration(seconds: 6),
                                    action: SnackBarAction(
                                      label: 'Buka Galeri',
                                      onPressed: () async => Gal.open(),
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                'Save',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStatePropertyAll(Colors.red),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Close',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  }
                }
              },
              style: ButtonStyle(
                backgroundColor: MaterialStatePropertyAll(Colors.teal[300]),
              ),
              child: Text(
                'Hapus Background Gambar',
                style: TextStyle(color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}
