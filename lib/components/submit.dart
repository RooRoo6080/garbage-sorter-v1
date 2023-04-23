import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

var apiKey = 'acc_efe693c3fe54a43';
var apiSecret = 'ba38b159835ce4800017651f7b1e5ba4';
var imageUrl = 'https://imagga.com/static/images/tagging/wind-farm-538576_640.jpg';

Future<http.Response> createAlbum(String title) {
  return http.post(
    Uri.parse('https://api.imagga.com/v2/tags'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'title': title,
    }),
  );
}

class Submit extends StatelessWidget {
  const Submit({super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}