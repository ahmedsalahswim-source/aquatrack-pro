import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:aquatrack_pro/core/theme/app_theme.dart';
import 'package:aquatrack_pro/core/models/pose_overlay_data.dart';
import 'package:aquatrack_pro/features/swim_vision/presentation/widgets/pose_overlay_painter.dart';

class PoseVideoPlayer extends StatefulWidget {
  final String videoPath;
  final List<PoseOverlayData> poseDataList;

  const PoseVideoPlayer({
    super.key,
    required this.videoPath,
    required this.poseDataList,
  });

  @override
  State<PoseVideoPlayer> createState() => _PoseVideoPlayerState();
}

class _PoseVideoPlayerState extends State<PoseVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  PoseOverlayData? _currentPose;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final file = File(widget.videoPath);
    if (!file.existsSync()) {
      return;
    }

    _controller = VideoPlayerController.file(file);
    await _controller.initialize();
    
    _controller.addListener(_onVideoPositionChanged);
    _controller.setLooping(true);
    
    setState(() {
      _isInitialized = true;
    });
  }

  void _onVideoPositionChanged() {
    if (!_controller.value.isInitialized) return;
    
    final currentTime = _controller.value.position.inMilliseconds / 1000.0;
    
    // Find closest pose data based on timestamp
    PoseOverlayData? closestPose;
    double minDiff = double.infinity;
    
    for (final pose in widget.poseDataList) {
      final diff = (pose.timestampSeconds - currentTime).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestPose = pose;
      }
    }
    
    // Only update state if the closest pose has changed
    if (closestPose != _currentPose) {
      setState(() {
        _currentPose = closestPose;
      });
    }
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _controller.removeListener(_onVideoPositionChanged);
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        height: 250,
        color: Colors.black12,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      children: [
        Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.black,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                VideoPlayer(_controller),
                CustomPaint(
                  painter: PoseOverlayPainter(
                    poseData: _currentPose,
                    originalVideoSize: _controller.value.size,
                  ),
                ),
                // Play/Pause Overlay
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_controller.value.isPlaying) {
                        _controller.pause();
                      } else {
                        _controller.play();
                      }
                    });
                  },
                  child: AnimatedOpacity(
                    opacity: _controller.value.isPlaying ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      color: Colors.black26,
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_fill_rounded,
                          size: 64,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Progress Bar
        VideoProgressIndicator(
          _controller,
          allowScrubbing: true,
          colors: const VideoProgressColors(
            playedColor: AppColors.primary,
            bufferedColor: AppColors.border,
            backgroundColor: Colors.black12,
          ),
        ),
      ],
    );
  }
}
