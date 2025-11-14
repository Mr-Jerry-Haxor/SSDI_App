import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../utils/logger.dart';

class FaceNetModel {
  static const int inputSize = 160;
  static const int embeddingSize = 512;
  
  // FaceNet normalization constants
  static const double mean = 127.5;
  static const double std = 128.0;

  Interpreter? _interpreter;
  bool _isModelLoaded = false;

  // Load the model
  Future<bool> loadModel() async {
    if (_isModelLoaded && _interpreter != null) {
      return true;
    }
    
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/facenet.tflite');
      _isModelLoaded = true;
      AppLogger.info('✅ FaceNet model loaded successfully');
      
      // Log input/output tensor info
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      AppLogger.debug('Input shape: $inputShape, Output shape: $outputShape');
      
      return true;
    } catch (e) {
      AppLogger.error('❌ Error loading FaceNet model', e);
      _isModelLoaded = false;
      return false;
    }
  }

  // Get face embedding
  Future<List<double>?> getEmbedding(img.Image faceImage) async {
    if (!_isModelLoaded || _interpreter == null) {
      AppLogger.warning('Model not loaded, attempting to load...');
      final loaded = await loadModel();
      if (!loaded) {
        AppLogger.error('Failed to load model');
        return null;
      }
    }

    try {
      // Resize image to 160x160
      final resized = img.copyResize(
        faceImage, 
        width: inputSize, 
        height: inputSize,
        interpolation: img.Interpolation.cubic,
      );
      
      AppLogger.debug('Image resized to ${resized.width}x${resized.height}');

      // Convert to input tensor with proper normalization
      final input = _imageToInputTensor(resized);

      // Output buffer - shape [1, 512]
      final output = List.generate(1, (_) => List.filled(embeddingSize, 0.0));

      // Run inference
      _interpreter!.run(input, output);
      
      final embedding = output[0];
      AppLogger.info('✅ Embedding generated: ${embedding.length} dimensions');
      
      // Normalize the embedding (L2 normalization)
      return _normalizeEmbedding(embedding);
    } catch (e) {
      AppLogger.error('Error getting embedding', e);
      return null;
    }
  }

  // Convert image to input tensor with FaceNet preprocessing
  List<List<List<List<double>>>> _imageToInputTensor(img.Image image) {
    // Shape: [1, 160, 160, 3]
    final input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) => List.filled(3, 0.0),
        ),
      ),
    );

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = image.getPixel(x, y);
        
        // FaceNet preprocessing: (pixel - 127.5) / 128.0
        // This normalizes from [0, 255] to approximately [-1, 1]
        input[0][y][x][0] = (pixel.r.toDouble() - mean) / std;
        input[0][y][x][1] = (pixel.g.toDouble() - mean) / std;
        input[0][y][x][2] = (pixel.b.toDouble() - mean) / std;
      }
    }

    return input;
  }
  
  // L2 normalize the embedding
  List<double> _normalizeEmbedding(List<double> embedding) {
    double sum = 0.0;
    for (final value in embedding) {
      sum += value * value;
    }
    final norm = _sqrt(sum);
    
    if (norm == 0.0) {
      AppLogger.warning('Embedding norm is zero');
      return embedding;
    }
    
    return embedding.map((value) => value / norm).toList();
  }

  // Calculate cosine similarity between two embeddings
  // Assumes embeddings are already L2 normalized
  static double cosineSimilarity(List<double> embedding1, List<double> embedding2) {
    if (embedding1.length != embedding2.length) {
      AppLogger.error('Embedding size mismatch: ${embedding1.length} vs ${embedding2.length}');
      return 0.0;
    }
    
    double dotProduct = 0.0;
    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
    }
    
    // If embeddings are L2 normalized, dot product is the cosine similarity
    return dotProduct;
  }

  // Helper function for square root using Newton's method
  static double _sqrt(double value) {
    if (value < 0) return 0.0;
    if (value == 0) return 0.0;
    
    double x = value;
    double y = 1.0;
    double epsilon = 0.000001;
    
    while ((x - y).abs() > epsilon) {
      x = (x + y) / 2.0;
      y = value / x;
    }
    return x;
  }

  void dispose() {
    _interpreter?.close();
  }
}
