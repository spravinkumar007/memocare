import 'dart:async'; // for Timer
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/storage_keys.dart';

class RealFaceAuthScreen extends StatefulWidget {
  const RealFaceAuthScreen({super.key});

  @override
  State<RealFaceAuthScreen> createState() => _RealFaceAuthScreenState();
}

class _RealFaceAuthScreenState extends State<RealFaceAuthScreen> {
  CameraController? _cameraController;
  final FaceDetector _faceDetector = GoogleMlKit.vision.faceDetector(
    FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      enableClassification: true,
    ),
  );
  bool _isProcessing = false;
  bool _isAuthenticated = false;
  String _status = "Initializing camera...";
  Timer? _captureTimer;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      setState(() => _status = "Camera permission denied");
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      setState(() => _status = "No camera found");
      return;
    }

    final frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() {
        _status = "Scanning face...";
      });
      _startPeriodicCapture();
    } catch (e) {
      setState(() => _status = "Camera error: $e");
    }
  }

  void _startPeriodicCapture() {
    // Capture a picture every second and process it
    _captureTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_isProcessing || _isAuthenticated || _cameraController == null) return;
      _isProcessing = true;
      try {
        // Take a picture
        final XFile picture = await _cameraController!.takePicture();
        final File imageFile = File(picture.path);

        // Process the image
        final inputImage = InputImage.fromFile(imageFile);
        final faces = await _faceDetector.processImage(inputImage);

        // Delete temp file
        imageFile.delete();

        if (faces.isNotEmpty && !_isAuthenticated) {
          _isAuthenticated = true;
          _captureTimer?.cancel();
          await _onFaceDetected();
        }
      } catch (e) {
        print("Face detection error: $e");
      } finally {
        _isProcessing = false;
      }
    });
  }

  Future<void> _onFaceDetected() async {
    setState(() {
      _status = "Face detected! Authenticating...";
    });

    await Future.delayed(const Duration(milliseconds: 500));

    const storage = FlutterSecureStorage();
    final isRegistered = await storage.read(key: StorageKeys.faceRegistered);
    if (isRegistered == null) {
      await storage.write(key: StorageKeys.faceRegistered, value: 'true');
    }

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    }
  }

  @override
  void dispose() {
    _captureTimer?.cancel();
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_cameraController != null && _cameraController!.value.isInitialized)
            CameraPreview(_cameraController!)
          else
            Container(color: Colors.black),
          Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.face,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  if (_status.contains("denied") || _status.contains("error"))
                    ElevatedButton(
                      onPressed: _initCamera,
                      child: const Text("Retry"),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}