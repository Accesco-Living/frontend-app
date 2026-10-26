import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'swadisht_intro_screen.dart';

class SwadishtSplashScreen extends StatefulWidget {
  const SwadishtSplashScreen({super.key});

  @override
  State<SwadishtSplashScreen> createState() => _SwadishtSplashScreenState();
}

class _SwadishtSplashScreenState extends State<SwadishtSplashScreen> {
  VideoPlayerController? _controller;
  bool _videoReady = false;
  bool _videoFailed = false;
  bool _navigated = false;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final controller =
          VideoPlayerController.asset('assets/videos/swadishtt_splash.mp4');
      
      await controller.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Video init timed out'),
      );
      
      if (!mounted) {
        controller.dispose();
        return;
      }

      // Explicitly set volume to 1.0 to prevent Android autoplay blocking
      await controller.setVolume(1.0);
      
      setState(() {
        _controller = controller;
        _videoReady = true;
      });
      
      // Add listener first
      controller.addListener(_onVideoProgress);
      
      // Play after a tiny delay to ensure the widget tree is mounted
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller?.play();
      });

    } catch (e) {
      debugPrint('SwadishtSplashScreen video failed: $e');
      if (mounted) {
        setState(() {
          _videoFailed = true;
          _errorMsg = e.toString();
        });
        // Wait 3 seconds so the user can read the error before skipping
        await Future.delayed(const Duration(seconds: 3));
        _navigateToApp();
      }
    }
  }

  void _onVideoProgress() {
    if (_controller == null) return;
    
    // Check if video has reached the end
    if (_controller!.value.isInitialized) {
      final pos = _controller!.value.position;
      final dur = _controller!.value.duration;
      
      if (dur.inMilliseconds > 0 && 
          pos.inMilliseconds > 500 && 
          pos.inMilliseconds >= dur.inMilliseconds - 150) {
        _controller!.removeListener(_onVideoProgress);
        _navigateToApp();
      }
    }
  }

  void _navigateToApp() {
    if (!mounted || _navigated) return;
    _navigated = true;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const SwadishtIntroScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoProgress);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_videoFailed) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text('Video failed to load.', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_errorMsg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
    }

    // Safely calculate aspect ratio to prevent stretching from rotation metadata
    double videoAspect = 9 / 16;
    if (_controller != null && _controller!.value.isInitialized) {
      final w = _controller!.value.size.width;
      final h = _controller!.value.size.height;
      // If it's a portrait video but claims to be wider than tall, force portrait ratio
      videoAspect = w > h ? h / w : w / h;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: _videoReady && _controller != null && _controller!.value.isInitialized
          ? GestureDetector(
              onTap: _navigateToApp, // Allow tap to skip
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: 1080,
                    height: 1920,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: videoAspect,
                        child: VideoPlayer(_controller!),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : const Center(
              child: CircularProgressIndicator(color: Colors.redAccent),
            ),
    );
  }
}
