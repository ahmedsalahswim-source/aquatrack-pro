import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:aquatrack_pro/core/theme/app_theme.dart';

class CameraRecordScreen extends StatefulWidget {
  final void Function(File videoFile) onVideoCaptured;

  const CameraRecordScreen({super.key, required this.onVideoCaptured});

  @override
  State<CameraRecordScreen> createState() => _CameraRecordScreenState();
}

class _CameraRecordScreenState extends State<CameraRecordScreen>
    with WidgetsBindingObserver {
  CameraController? _camera;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  bool _isPreviewing = false;
  int _recordSeconds = 0;
  Timer? _timer;
  File? _recordedFile;
  VideoPlayerController? _previewController;
  bool _showGuide = true;
  bool _dontShowAgain = false;
  bool _cameraReady = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _camera?.dispose();
    _previewController?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    final camStatus = await Permission.camera.request();
    if (camStatus != PermissionStatus.granted) {
      setState(() => _errorMessage = 'نحتاج إذن الكاميرا لتصوير السباح');
      return;
    }
    final micStatus = await Permission.microphone.request();
    if (micStatus != PermissionStatus.granted) {
      setState(() => _errorMessage = 'نحتاج إذن الميكروفون أثناء التسجيل');
      return;
    }
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() => _errorMessage = 'لا توجد كاميرا متاحة');
        return;
      }
      final backCamera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );
      _camera = CameraController(backCamera, ResolutionPreset.high);
      await _camera!.initialize();
      if (mounted) {
        setState(() => _cameraReady = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'فشل تشغيل الكاميرا: $e');
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    final currentLens = _camera?.description.lensDirection;
    final newCamera = _cameras!.firstWhere(
      (c) => c.lensDirection != currentLens,
      orElse: () => _cameras!.first,
    );
    final old = _camera;
    _camera = CameraController(newCamera, ResolutionPreset.high);
    await _camera!.initialize();
    old?.dispose();
    if (mounted) setState(() {});
  }

  Future<void> _startRecording() async {
    if (_camera == null || !_camera!.value.isInitialized) return;
    try {
      await _camera!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _recordSeconds = 0;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        setState(() => _recordSeconds = t.tick);
        if (t.tick >= 60) _stopRecording();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل بدء التسجيل: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (_camera == null || !_isRecording) return;
    try {
      _timer?.cancel();
      final file = await _camera!.stopVideoRecording();
      
      if (_recordSeconds < 3) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('الفيديو قصير جداً (أقل من 3 ثوانٍ). يرجى التصوير لمدة أطول.')),
          );
        }
        try { File(file.path).deleteSync(); } catch (_) {}
        setState(() => _isRecording = false);
        return;
      }

      _recordedFile = File(file.path);
      _previewController = VideoPlayerController.file(_recordedFile!);
      await _previewController!.initialize();
      setState(() {
        _isRecording = false;
        _isPreviewing = true;
      });
      _previewController!.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل إيقاف التسجيل: $e')),
        );
      }
      setState(() => _isRecording = false);
    }
  }

  void _retake() {
    _previewController?.dispose();
    _previewController = null;
    _recordedFile = null;
    _timer?.cancel();
    if (mounted) setState(() => _isPreviewing = false);
  }

  String _formatTime(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return _buildPermissionError();
    }
    if (_isPreviewing && _recordedFile != null) {
      return _buildPreview();
    }
    if (!_cameraReady) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('جاري تشغيل الكاميرا...', style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }
    return _buildCameraView();
  }

  Widget _buildCameraView() {
    return Stack(
      children: [
        if (_camera != null && _camera!.value.isInitialized)
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: CameraPreview(_camera!),
          ),
        // Guide overlay
        if (_showGuide)
          Semantics(
            button: true,
            label: 'إغلاق الدليل',
            child: InkWell(
              onTap: () => setState(() => _showGuide = false),
              child: Container(
                color: Colors.black45,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 280,
                        height: 160,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white54, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'ضع السباح داخل الإطار',
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'اضغط في أي مكان للإغلاق',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: _dontShowAgain,
                            onChanged: (v) => setState(() => _dontShowAgain = v ?? false),
                            fillColor: WidgetStateProperty.all(Colors.white54),
                          ),
                          const Text(
                            'لا تظهر مجدداً',
                            style: TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        // Top bar
        Positioned(
          top: 16,
          left: 16,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        // Timer & recording indicator
        if (_isRecording)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.fiber_manual_record, color: Colors.red, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _formatTime(_recordSeconds),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        // Bottom controls
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isRecording)
                IconButton(
                  icon: const Icon(Icons.flip_camera_android, color: Colors.white, size: 28),
                  onPressed: _switchCamera,
                ),
              const SizedBox(width: 24),
              Semantics(
                button: true,
                label: _isRecording ? 'إيقاف التسجيل' : 'بدء التسجيل',
                child: InkWell(
                  onTap: _isRecording ? _stopRecording : _startRecording,
                  borderRadius: BorderRadius.circular(36),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording ? Colors.red : Colors.white,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: _isRecording
                        ? const Center(
                            child: Icon(Icons.stop, color: Colors.white, size: 32),
                          )
                        : const SizedBox(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return Stack(
      children: [
        if (_previewController != null && _previewController!.value.isInitialized)
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: VideoPlayer(_previewController!),
          ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _retake,
                icon: const Icon(Icons.replay),
                label: const Text('إعادة التصوير'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white24,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  if (_recordedFile != null) {
                    widget.onVideoCaptured(_recordedFile!);
                  }
                },
                icon: const Icon(Icons.check_circle),
                label: const Text('تحليل الآن'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.white54),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: openAppSettings,
              icon: const Icon(Icons.settings),
              label: const Text('فتح الإعدادات'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('رجوع', style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }
}
