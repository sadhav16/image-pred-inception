import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:fdcm/models/gemini_waiter.dart';

class ImagePredictor extends StatefulWidget {
  const ImagePredictor({super.key});

  @override
  _ImagePredictorState createState() => _ImagePredictorState();
}

class _ImagePredictorState extends State<ImagePredictor> {
  File? _image;
  String _prediction = "No prediction yet";
  String _geminiResponse = "Calorie Genie";
  bool _isLoading = false;

  final String apiUrl = "https://image-pred-inception.onrender.com/predict"; // Flask server IP
  GeminiService geminiService = GeminiService(); // Instantiate GeminiService

  Future<void> _pickImage(ImageSource source) async {
  final pickedFile = await ImagePicker().pickImage(source: source);

  if (pickedFile != null) {
    setState(() {
      _image = File(pickedFile.path);
      _geminiResponse = "Calorie Genie"; // Reset AI response
      geminiService = GeminiService(); // Reinitialize to clear past prompts
    });
    _predictImage();
  }
}


  Future<void> _predictImage() async {
    if (_image == null) return;

    setState(() {
      _isLoading = true;
      _prediction = "Predicting...";
    });

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.files.add(await http.MultipartFile.fromPath('file', _image!.path));

      var response = await request.send();
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(await response.stream.bytesToString());
        setState(() {
          _prediction = jsonResponse['prediction'].toString();
        });

        // Send prediction to Gemini AI
        _fetchGeminiResponse(jsonResponse['prediction'].toString());
      } else {
        setState(() {
          _prediction = "Error: ${response.reasonPhrase}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _prediction = "Error: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchGeminiResponse(String prediction) async {
    setState(() {
      _geminiResponse = "Getting insights...";
    });

    String response = await geminiService.generateResponse(
        "I'm going to eat $prediction. How many calories will I gain from it, and in what quantity should I consume it?");

    setState(() {
      _geminiResponse = response;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text("NomNomMeter"),
        centerTitle: true,
        ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _image != null
                  ? Image.file(_image!, height: screenHeight * 0.3, width: screenWidth * 0.8, fit: BoxFit.cover)
                  : const Icon(Icons.image, size: 100, color: Colors.grey),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    child: const Text("Select Image"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.camera),
                    child: const Text("Take Photo"),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      children: [
                        Text("Prediction: $_prediction", style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 10),
                        Container(
                          width: screenWidth * 0.9,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blueAccent),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: MarkdownBody(data: _geminiResponse),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
