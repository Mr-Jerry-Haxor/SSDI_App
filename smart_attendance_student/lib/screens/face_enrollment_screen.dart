import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
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
  bool _cameraPermissionDenied = false;

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
      // Check camera permission first
      final status = await Permission.camera.status;
      if (status.isDenied) {
        setState(() {
          _cameraPermissionDenied = true;
        });
        return;
      }
      
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

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() {
        _cameraPermissionDenied = false;
      });
      await _initializeCamera();
    } else if (status.isPermanentlyDenied) {
      _showSnackBar(
        'Camera permission permanently denied. Please enable it in Settings.',
        Colors.red,
      );
      openAppSettings();
    } else {
      _showSnackBar('Camera permission is required to enroll face', Colors.orange);
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
    // Show permission request UI if camera permission is denied
    if (_cameraPermissionDenied) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Face Enrollment'),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.camera_alt_outlined,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Camera Permission Required',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'We need camera access to capture your face for attendance verification.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _requestCameraPermission,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Grant Camera Permission'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
