import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/storage_keys.dart';

class RealFaceAuthScreen extends StatefulWidget {
  const RealFaceAuthScreen({super.key});

  @override
  State<RealFaceAuthScreen> createState() => _RealFaceAuthScreenState();
}

class _RealFaceAuthScreenState extends State<RealFaceAuthScreen> {
  CameraController? _cameraController;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      enableClassification: true,
    ),
  );
  bool _isDetecting = false;
  bool _isAuthenticated = false;
  String _status = "Initializing camera...";

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
      ResolutionPreset.low,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        _status = "Scanning face...";
      });

      _startPeriodicDetection();

    } catch (e) {
      setState(() => _status = "Camera error: $e");
    }
  }

  void _startPeriodicDetection() {
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_isDetecting || _isAuthenticated || _cameraController == null || !_cameraController!.value.isInitialized) return;

      _isDetecting = true;
      try {
        // Take a picture
        final XFile picture = await _cameraController!.takePicture();
        final File imageFile = File(picture.path);

        // Process the image
        final inputImage = InputImage.fromFile(imageFile);
        final faces = await _faceDetector.processImage(inputImage);

        // Delete temp file
        await imageFile.delete();

        if (faces.isNotEmpty && !_isAuthenticated) {
          _isAuthenticated = true;
          timer.cancel();
          await _stopCamera();
          if (mounted) {
            await _onFaceDetected();
          }
        }
      } catch (e) {
        print("Face detection error: $e");
      } finally {
        _isDetecting = false;
      }
    });
  }

  Future<void> _stopCamera() async {
    try {
      if (_cameraController != null) {
        await _cameraController!.dispose();
        _cameraController = null;
      }
    } catch (e) {
      print("Error stopping camera: $e");
    }
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
    _stopCamera();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full screen camera preview
          if (_cameraController != null && _cameraController!.value.isInitialized)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            )
          else
            Container(color: Colors.black),

          // Overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Face outline guide
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.face,
                        size: 100,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Status text
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        _status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Hint text
                    if (_status == "Scanning face...")
                      const Text(
                        'Position your face in the circle',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),

                    // Retry button for errors
                    if (_status.contains("denied") || _status.contains("error") || _status.contains("No camera"))
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: ElevatedButton(
                          onPressed: _initCamera,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text("Retry"),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}