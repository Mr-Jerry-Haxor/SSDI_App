import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img;
import '../services/facenet_model.dart';
import '../services/face_storage.dart';
import '../utils/logger.dart';
import 'main_screen.dart';

class FaceEnrollmentScreen extends StatefulWidget {
  final String studentId;

  const FaceEnrollmentScreen({super.key, required this.studentId});

  @override
  State<FaceEnrollmentScreen> createState() => _FaceEnrollmentScreenState();
}

class _FaceEnrollmentScreenState extends State<FaceEnrollmentScreen> {
  CameraController? _cameraController;
  final _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: false,
      enableContours: false,
      enableClassification: false,
    ),
  );
  final _faceNetModel = FaceNetModel();
  
  bool _isProcessing = false;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadFaceNetModel();
  }
  
  Future<void> _loadFaceNetModel() async {
    try {
      final loaded = await _faceNetModel.loadModel();
      if (!loaded) {
        _showSnackBar('Failed to load face recognition model', Colors.red);
      }
    } catch (e) {
      AppLogger.error('Error loading FaceNet model', e);
      _showSnackBar('Error loading face recognition model', Colors.red);
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showSnackBar('No camera available', Colors.red);
        return;
      }

      // Get front camera
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      AppLogger.error('Camera initialization error', e);
      _showSnackBar('Camera error: $e', Colors.red);
    }
  }

  Future<void> _captureFace() async {
    if (_isProcessing || _cameraController == null || !_isCameraInitialized || !(_cameraController!.value.isInitialized)) {
      _showSnackBar('Camera not ready. Please wait...', Colors.orange);
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile imageFile = await _cameraController!.takePicture();
      final bytes = await imageFile.readAsBytes();

      // Decode image
      final capturedImage = img.decodeImage(bytes);
      if (capturedImage == null) {
        _showSnackBar('Failed to decode image', Colors.red);
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Detect face using ML Kit
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        _showSnackBar('No face detected. Please try again.', Colors.orange);
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Crop face with proper bounds
      final face = faces.first;
      final faceRect = face.boundingBox;
      
      AppLogger.debug('Face detected at: ${faceRect.left}, ${faceRect.top}, ${faceRect.width}x${faceRect.height}');
      AppLogger.debug('Image size: ${capturedImage.width}x${capturedImage.height}');
      
      // Calculate crop bounds with padding
      final padding = 20; // Add padding around face
      final x = (faceRect.left.toInt() - padding).clamp(0, capturedImage.width - 1);
      final y = (faceRect.top.toInt() - padding).clamp(0, capturedImage.height - 1);
      final width = (faceRect.width.toInt() + 2 * padding).clamp(1, capturedImage.width - x);
      final height = (faceRect.height.toInt() + 2 * padding).clamp(1, capturedImage.height - y);
      
      AppLogger.debug('Cropping face: x=$x, y=$y, w=$width, h=$height');
      
      final croppedFace = img.copyCrop(
        capturedImage,
        x: x,
        y: y,
        width: width,
        height: height,
      );
      
      AppLogger.debug('Face cropped: ${croppedFace.width}x${croppedFace.height}');

      // Get embedding
      _showSnackBar('Processing face...', Colors.blue);
      final embedding = await _faceNetModel.getEmbedding(croppedFace);

      if (embedding == null || embedding.isEmpty) {
        _showSnackBar('Failed to generate face embedding. Please try again.', Colors.red);
        setState(() {
          _isProcessing = false;
        });
        return;
      }
      
      AppLogger.info('Face embedding generated successfully with ${embedding.length} dimensions');

      // Save embedding
      await FaceStorage.saveEmbedding(embedding);

      if (!mounted) return;

      _showSnackBar('✅ Face registered successfully!', Colors.green);

      // Navigate to main screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MainScreen(studentId: widget.studentId),
        ),
      );
    } catch (e) {
      AppLogger.error('Face capture error', e);
      _showSnackBar('Error: $e', Colors.red);
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    _faceNetModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Enrollment'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isCameraInitialized && _cameraController != null
                ? CameraPreview(_cameraController!)
                : const Center(
                    child: CircularProgressIndicator(),
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(24.0),
            color: Colors.black87,
            child: Column(
              children: [
                const Text(
                  'Position your face in the camera',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _captureFace,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.camera_alt),
                  label: Text(_isProcessing ? 'Processing...' : 'Capture Face'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
