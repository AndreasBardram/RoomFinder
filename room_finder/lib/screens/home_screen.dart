import 'package:flutter/material.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  Future<void> _uploadTest() async {
    try {
      //await FirebaseFirestore.instance.collection('test').add({
        //'message': 'Hello from Flutter!',
        //'timestamp': DateTime.now().toUtc().toString(),
      //});
      //debugPrint('Successfully uploaded test document!');
    } catch (e) {
      debugPrint('Error uploading test document: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: ElevatedButton(
          onPressed: _uploadTest,
          child: const Text('Upload Test Document'),
        ),
      ),
    );
  }
}
