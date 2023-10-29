// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:dart_openai/openai.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

String? imageUrl;
String outputBin = "";

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
  TextEditingController textController = TextEditingController();

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
                    // debugPrint(Uri.dataFromBytes(bytes, mimeType: 'image/png')
                        // .toString()
                        // .substring(22));
                    String tag = await categorizer(bytes);
                    setState(() {
                      outputBin = tag;
                    });
                  },
            child: const Text('Take picture'),
          ),
          const SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(200, 20, 200, 20),
            child: TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: "Item description",
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              String o = await completionBin(textController.text);
              setState(() {
                outputBin = o;
              });
            },
            child: const Text('Submit'),
          ),
          const SizedBox(
            height: 20,
          ),
          const Divider(
            height: 5,
            thickness: 5,
            indent: 20,
            endIndent: 20,
          ),
          Text(
            outputBin,
            style: const TextStyle(
              fontSize: 50,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

Future<String> completionBin (input) async {
  OpenAI.apiKey = "API KEY";
  final completion = await OpenAI.instance.completion.create(
    model: "text-davinci-003",
    prompt:
        "What goes in the recycling bin: plastics, soda and juice bottles, milk jugs, water jugs, rigid plastic containers, creates and trays, tin, aluminum, scrap metal, steel cans, dishes, empty aerosol cans, soup cartons, clean egg cartons, paper file folders, paper file folders, junk mail, magazines, milk and juice cartons, newspaper, paper, books, paper bags, post-it notes, clean cardboard, cereal boxes, frozen food boxes, beverage bottles, glass. What goes in the trash bin: candy wrappers, vegetables, chip bags, juice pouches, coffee pods, food, paper cups, straws, plastic utensils, dishes, flower pots, vases, paper plates, food soiled items, gift wrap, tissues, toilet papaer, laminated paper, photographs, hardback book covers, stickers, plastic golves, styrofoam, bubble wrap, unusable clothing, unusable fabric. Which bin does$input go in? Respond with onlyeither 'Recycle' or 'Trash'.",
  );
  // debugPrint("completion input tag: $input");
  // debugPrint("completion output: ${completion.choices[0].text.trim()}");
  return completion.choices[0].text.trim().replaceAll('.', '');
}

Future<String> categorizer(image) async {
  // debugPrint('ACTIVATED');
  final url = Uri.parse(
      "https://api.imgbb.com/1/upload?expiration=600&key=c02d9a6d19488064be587c3e0f8fcdce");
  final imageBase64 =
      Uri.dataFromBytes(image, mimeType: 'image/png').toString().substring(22);

  try {
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: {
        "image": imageBase64,
      },
    );

    if (response.statusCode == 200) {
      // debugPrint("UPLOAD SUCCESSFUL");
      // debugPrint(response.body);
      String link = response.body
          .substring(response.body.indexOf('"url":"') + 7,
              response.body.indexOf('","display_url'))
          .replaceAll(r'\', '');
      // debugPrint(link);
      String apiUrl = 'https://api.imagga.com/v2/tags?image_url=$link';
      // debugPrint(apiUrl);
      const String key = 'KEY';
      const String secret = 'SECRET';

      final tags = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$key:$secret'))}'
        },
      );

      if (tags.statusCode == 200) {
        // debugPrint('Response data: ${tags.body}');
        String tag = tags.body.substring(
            tags.body.indexOf('en":"') + 5, tags.body.indexOf('"}},'));
        // debugPrint("categorizer: $tag");
        return completionBin(tag);
      } else {
        debugPrint('Request failed with status code: ${response.statusCode}');
        debugPrint('Response body: ${tags.body}');
      }
    } else {
      debugPrint("Failed to upload. Status code: ${response.statusCode}");
    }
  } catch (e) {
    debugPrint("Error: $e");
  }
  return "-1";
}
