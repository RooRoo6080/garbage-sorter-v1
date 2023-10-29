import 'package:flutter/material.dart';
import 'package:rubbish_sorter/components/image_taker.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(
        children: [
          AppBody(),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
