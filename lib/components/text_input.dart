import 'package:flutter/material.dart';
import 'package:dart_openai/openai.dart';

class TextInput extends StatefulWidget {
  const TextInput({super.key});

  @override
  State<TextInput> createState() => _TextInputState();
}
String output = "";
String input = "";

class _TextInputState extends State<TextInput> {
  TextEditingController textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
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
              String o = await completion();
              setState(() {
                input = textController.text;
                output = o;
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
            output,
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

Future<String> completion() async {
  OpenAI.apiKey = "OPENAI-API-KEY";
  final completion = await OpenAI.instance.completion.create(
    model: "text-davinci-003",
    prompt:
        "What goes in the recycling bin: plastics, soda and juice bottles, milk jugs, water jugs, rigid plastic containers, creates and trays, tin, aluminum, scrap metal, steel cans, dishes, empty aerosol cans, soup cartons, clean egg cartons, paper file folders, paper file folders, junk mail, magazines, milk and juice cartons, newspaper, paper, books, paper bags, post-it notes, clean cardboard, cereal boxes, frozen food boxes, beverage bottles, glass.\nWhat goes in the trash bin: candy wrappers, vegetables, chip bags, juice pouches, coffee pods, food, paper cups, straws plastic utensils, dishes, flower pots, vases, paper plates, food soiled items, gift wrap, tissues, toilet papaer, laminated paper, photographs, hardback book covers, stickers, plastic golves, styrofoam, bubble wrap, unusable clothing, unusable fabric.\nWhich bin does$input go in? Respond with either 'Recycle' or 'Trash'.",
  );
  debugPrint(completion.choices[0].text);
  return completion.choices[0].text;
}
