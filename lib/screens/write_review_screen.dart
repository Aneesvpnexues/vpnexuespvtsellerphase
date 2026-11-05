import 'package:flutter/material.dart';
class WriteReviewScreen extends StatelessWidget {
  const WriteReviewScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Write a Review')), body: const Padding(padding: EdgeInsets.all(16), child: Column(children: [Text('Star Rating'), TextField(maxLines: 3, decoration: InputDecoration(border: OutlineInputBorder(), hintText: 'Your review...')), SizedBox(height: 20), ElevatedButton(onPressed: null, child: Text('Submit'))])));
}
