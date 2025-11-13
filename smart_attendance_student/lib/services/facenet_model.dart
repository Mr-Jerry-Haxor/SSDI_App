import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../utils/logger.dart';

class FaceNetModel {
  static const int inputSize = 160;
  static const int embeddingSize = 512;

  Interpreter? _interpreter;

  // Load the model
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/facenet.tflite');
      AppLogger.info('✅ FaceNet model loaded');
    } catch (e) {
      AppLogger.error('❌ Error loading FaceNet model', e);
    }
  }

  // Get face embedding
  Future<List<double>?> getEmbedding(img.Image faceImage) async {
    if (_interpreter == null) {
      await loadModel();
    }

    if (_interpreter == null) {
      AppLogger.warning('Model not loaded');
      return null;
    }

    try {
      // Resize image to 160x160
      final resized = img.copyResize(faceImage, width: inputSize, height: inputSize);

      // Normalize and convert to float32
      final input = _imageToByteListFloat32(resized);

      // Output buffer
      final output = List.filled(1 * embeddingSize, 0.0).reshape([1, embeddingSize]);

      // Run inference
      _interpreter!.run(input, output);

      return output[0].cast<double>();
    } catch (e) {
      AppLogger.error('Error getting embedding', e);
      return null;
    }
  }

  // Convert image to float32 list
  Float32List _imageToByteListFloat32(img.Image image) {
    final convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    final buffer = Float32List.view(convertedBytes.buffer);

    int pixelIndex = 0;
    for (int i = 0; i < inputSize; i++) {
      for (int j = 0; j < inputSize; j++) {
        final pixel = image.getPixel(j, i);
        
        // Normalize to [0, 1]
        buffer[pixelIndex++] = pixel.r / 255.0;
        buffer[pixelIndex++] = pixel.g / 255.0;
        buffer[pixelIndex++] = pixel.b / 255.0;
      }
    }

    return convertedBytes;
  }

  // Calculate cosine similarity between two embeddings
  static double cosineSimilarity(List<double> embedding1, List<double> embedding2) {
    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;

    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
      norm1 += embedding1[i] * embedding1[i];
      norm2 += embedding2[i] * embedding2[i];
    }

    if (norm1 == 0.0 || norm2 == 0.0) return 0.0;

    return dotProduct / (sqrt(norm1) * sqrt(norm2));
  }

  // Helper function for square root
  static double sqrt(double value) {
    double x = value;
    double y = 1;
    double e = 0.000001;
    while (x - y > e) {
      x = (x + y) / 2;
      y = value / x;
    }
    return x;
  }

  void dispose() {
    _interpreter?.close();
  }
}
