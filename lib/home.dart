import 'package:flutter/material.dart';
import 'package:rubbish_sorter/components/image_taker.dart';
// import 'package:rubbish_sorter/components/image_taker2.dart';
import 'package:rubbish_sorter/components/text_input.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: const [
          AppBody(),
          // TakePictureScreen(camera: await availableCameras),
          Divider(
            height: 20,
            thickness: 5,
            indent: 20,
            endIndent: 20,
          ),
          TextInput(),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
