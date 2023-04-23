// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
// ignore: import_of_legacy_library_into_null_safe
import 'package:universal_io/io.dart' as uio;
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

String? imageUrl;

class CameraApp extends StatefulWidget {
  const CameraApp({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: AppBody(),
        ));
  }
}

class AppBody extends StatefulWidget {
  const AppBody({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AppBodyState createState() => _AppBodyState();
}

class _AppBodyState extends State<AppBody> {
  bool cameraAccess = false;
  String? error;
  List<CameraDescription>? cameras;

  @override
  void initState() {
    getCameras();
    super.initState();
  }

  Future<void> getCameras() async {
    try {
      await window.navigator.mediaDevices!
          .getUserMedia({'video': true, 'audio': false});
      setState(() {
        cameraAccess = true;
      });
      final cameras = await availableCameras();
      setState(() {
        this.cameras = cameras;
      });
    } on DomException catch (e) {
      setState(() {
        error = '${e.name}: ${e.message}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Center(child: Text('Error: $error'));
    }
    if (!cameraAccess) {
      return const Center(child: Text('Camera access not granted yet.'));
    }
    if (cameras == null) {
      return const Center(child: Text('Reading cameras'));
    }
    return CameraView(cameras: cameras!);
  }
}

class CameraView extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraView({Key? key, required this.cameras}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  String? error;
  CameraController? controller;
  late CameraDescription cameraDescription = widget.cameras[0];

  Future<void> initCam(CameraDescription description) async {
    setState(() {
      controller = CameraController(description, ResolutionPreset.low);
    });

    try {
      await controller!.initialize();
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    initCam(cameraDescription);
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Center(
        child: Text('Initializing error: $error\nCamera list:'),
      );
    }
    if (controller == null) {
      return const Center(child: Text('Loading controller...'));
    }
    if (!controller!.value.isInitialized) {
      return const Center(child: Text('Initializing camera...'));
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(500, 20, 500, 20),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: CameraPreview(controller!),
            ),
          ),
          Material(
            child: DropdownButton<CameraDescription>(
              value: cameraDescription,
              icon: const Icon(Icons.arrow_downward),
              iconSize: 24,
              elevation: 16,
              onChanged: (CameraDescription? newValue) async {
                if (controller != null) {
                  await controller!.dispose();
                }
                setState(() {
                  controller = null;
                  cameraDescription = newValue!;
                });

                initCam(newValue!);
              },
              items: widget.cameras
                  .map<DropdownMenuItem<CameraDescription>>((value) {
                return DropdownMenuItem<CameraDescription>(
                  value: value,
                  child: Text('${value.name}: ${value.lensDirection}'),
                );
              }).toList(),
            ),
          ),
          ElevatedButton(
            onPressed: controller == null
                ? null
                : () async {
                    final file = await controller!.takePicture();
                    final bytes = await file.readAsBytes();

                    final link = AnchorElement(
                        href: Uri.dataFromBytes(bytes, mimeType: 'image/png')
                            .toString());

                    link.download = 'picture.png';
                    link.click();
                    link.remove();
                    var picked = await FilePicker.platform.pickFiles();

                    if (picked != null) {
                      debugPrint(picked.files.first.name);
                    }

                    categorizer(uploadImage(picked));
                  },
            child: const Text('Take picture'),
          ),
          const SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }
}

Future<void> categorizer(image) async {
  debugPrint('ACTIVATED');

  const apiKey = 'IMAGGA-API-KEY';
  const apiSecret = 'IMAGGA-API-SECRET';
  imageUrl = image;
  var url = 'https://api.imagga.com/v2/tags?image_url=$imageUrl';
  final response = await http.get(Uri.parse(url), headers: {
    'Authorization': 'Basic ${base64Encode(utf8.encode('$apiKey:$apiSecret'))}'
  });
  if (response.statusCode == 200) {
    // Request successful
    debugPrint(response.body);
  } else {
    // Request failed
    debugPrint('Request failed with status: ${response.statusCode}.');
  }
}

Future<String> uploadImage(imageFile) async {
  final url = Uri.parse('https://freeimage.host/api/1/upload');
  final request = http.MultipartRequest('POST', url);
  request.headers['Content-Type'] = 'multipart/form-data';
  request.fields['key'] = 'FREEIMAGEHOST-API-KEY';

  final imageStream = http.ByteStream(imageFile.openRead());
  final imageLength = await imageFile.length();
  final imageUpload = http.MultipartFile(
    'source',
    imageStream,
    imageLength,
    filename: 'image.jpg',
  );

  request.files.add(imageUpload);
  final response = await request.send();

  if (response.statusCode == 200) {
    final responseJson = jsonDecode(await response.stream.bytesToString());
    final imageUrl = responseJson['image']['url'];
    debugPrint(imageUrl);
    return imageUrl;
  } else {
    throw Exception('Failed to upload image');
  }
}
