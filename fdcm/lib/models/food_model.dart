import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class ImageClassifier {
  late Interpreter interpreter; 
  late List<int> inputShape;
  late List<int> outputShape;
  final List<String> classNames; // Add your class names here

  ImageClassifier({required this.classNames});

  // Initialize function
  Future<void> initialize() async {
    await _loadModel();
  }

  // Load model function
  Future<void> _loadModel() async {
    try {
      // Load model from assets
      interpreter = await Interpreter.fromAsset('assets/models/my_model.tflite');
      
      // Get input and output shapes
      inputShape = interpreter.getInputTensor(0).shape;
      outputShape = interpreter.getOutputTensor(0).shape;
      
      if (kDebugMode) {
        print("Model loaded successfully");
      }
      if (kDebugMode) {
        print("Input shape: $inputShape");
      }
      if (kDebugMode) {
        print("Output shape: $outputShape");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error loading model: $e");
      }
    }
  }

  // Ensure initialization before preprocessing
  Future<List<double>> preprocessImage(File imageFile) async {
    if (inputShape.isEmpty || outputShape.isEmpty) {
      throw Exception('Model has not been initialized properly');
    }

    // Read and decode image
    final imageData = await imageFile.readAsBytes();
    final image = img.decodeImage(imageData);
    
    if (image == null) throw Exception('Failed to load image');

    // Resize image to match model input size
    final resizedImage = img.copyResize(
      image,
      width: inputShape[1],  // Model's expected width
      height: inputShape[2], // Model's expected height
    );

    // Convert to float32 list and normalize
    var buffer = List<double>.filled(inputShape[1] * inputShape[2] * 3, 0.0);
    var pixel = 0;
    
    for (var y = 0; y < resizedImage.height; y++) {
      for (var x = 0; x < resizedImage.width; x++) {
        var pixelColor = resizedImage.getPixel(x, y);
        buffer[pixel] = (img.getRed(pixelColor) / 255.0);      // Normalize red channel
        buffer[pixel + 1] = (img.getGreen(pixelColor) / 255.0);  // Normalize green channel
        buffer[pixel + 2] = (img.getBlue(pixelColor) / 255.0);   // Normalize blue channel
        pixel += 3;
      }
    }
    
    return buffer;
  }

  // Make sure that model is initialized before predicting
  Future<Map<String, dynamic>> predict(File imageFile) async {
    try {
      // Ensure model is initialized
      if (inputShape.isEmpty || outputShape.isEmpty) {
        throw Exception('Model has not been initialized properly');
      }
      
      // Preprocess image
      final imageData = await preprocessImage(imageFile);
      
      // Prepare input tensor (reshaping according to inputShape)
      var inputArray = Float32List(inputShape[0] * inputShape[1] * inputShape[2] * inputShape[3]);
      inputArray.setAll(0, imageData);
      
      // Prepare output tensor (flattened based on outputShape)
      var outputArray = Float32List(outputShape[0] * outputShape[1]);
      
      // Run inference
      interpreter.run(
        inputArray.reshape(inputShape),
        outputArray.reshape(outputShape),
      );

      // Find the class with the highest probability
      int maxIndex = 0;
      double maxValue = outputArray[0];
      
      for (int i = 0; i < outputArray.length; i++) {
        if (outputArray[i] > maxValue) {
          maxValue = outputArray[i];
          maxIndex = i;
        }
      }

      // Return result with class name, confidence, and raw output
      return {
        'class': classNames[maxIndex],
        'confidence': maxValue,
        'raw_output': List<double>.from(outputArray)
      };
    } catch (e) {
      print("Error during prediction: $e");
      rethrow;
    }
  }

  // Dispose of the interpreter when done
  void dispose() {
    interpreter.close();
  }
}