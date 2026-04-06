import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../services/translation_api_service.dart';

/// Voice Translation Screen
/// Records audio, sends to backend for transcription + translation,
/// and displays original + English translated text.
class VoiceTranslationScreen extends StatefulWidget {
  const VoiceTranslationScreen({super.key});

  @override
  State<VoiceTranslationScreen> createState() => _VoiceTranslationScreenState();
}

enum RecordingState { idle, recording, processing, result, error }

class _VoiceTranslationScreenState extends State<VoiceTranslationScreen>
    with TickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  RecordingState _state = RecordingState.idle;
  String _originalText = '';
  String _translatedText = '';
  String _detectedLanguage = '';
  String _errorMessage = '';
  int _latencyMs = 0;

  late AnimationController _pulseController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
  }

  @override
  void dispose() {
    _recorder.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        setState(() {
          _state = RecordingState.error;
          _errorMessage = 'Microphone permission denied';
        });
        return;
      }

      String? path;
      if (!kIsWeb) {
        final dir = await getTemporaryDirectory();
        path = '${dir.path}/voice_recording.m4a';
      }

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path ?? '', // The record package creates a blob URL on the web.
      );

      setState(() => _state = RecordingState.recording);
      _pulseController.repeat(reverse: true);
      _waveController.repeat();
    } catch (e) {
      setState(() {
        _state = RecordingState.error;
        _errorMessage = 'Failed to start recording: $e';
      });
    }
  }

  Future<void> _stopAndProcess() async {
    try {
      final path = await _recorder.stop();
      _pulseController.stop();
      _waveController.stop();

      if (path == null) {
        setState(() {
          _state = RecordingState.error;
          _errorMessage = 'No recording found';
        });
        return;
      }

      setState(() => _state = RecordingState.processing);

      final result = await TranslationApiService.transcribeAudio(path);

      setState(() {
        _state = RecordingState.result;
        _originalText = result['original'] ?? '';
        _translatedText = result['translated'] ?? '';
        _detectedLanguage = result['detected_language_name'] ?? 'Unknown';
        _latencyMs = result['latency_ms'] ?? 0;
      });
    } catch (e) {
      setState(() {
        _state = RecordingState.error;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _reset() {
    setState(() {
      _state = RecordingState.idle;
      _originalText = '';
      _translatedText = '';
      _detectedLanguage = '';
      _errorMessage = '';
      _latencyMs = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.lg),
            _buildTopBar(),
            Expanded(child: _buildBody()),
            _buildBottomActions(),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.textPrimary, size: 20),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Voice Translation',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary, letterSpacing: -0.3)),
                Text('Speak in any language',
                    style: TextStyle(fontSize: 13,
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (_state == RecordingState.recording)
            _RecordingBadge(animation: _pulseController),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return switch (_state) {
      RecordingState.idle => _buildIdleState(),
      RecordingState.recording => _buildRecordingState(),
      RecordingState.processing => _buildProcessingState(),
      RecordingState.result => _buildResultState(),
      RecordingState.error => _buildErrorState(),
    };
  }

  Widget _buildIdleState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.08),
            ),
            child: const Icon(Icons.translate_rounded,
                size: 56, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const Text('Tap to Record',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary, letterSpacing: -0.4)),
          const SizedBox(height: AppSpacing.sm),
          const Text('Speak in any language — we\'ll translate to English',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildRecordingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 180, height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ...List.generate(3, (i) {
                  return AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, _) {
                      final progress = ((_waveController.value + i * 0.33) % 1.0);
                      return Container(
                        width: 100 + (progress * 80),
                        height: 100 + (progress * 80),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary
                                .withValues(alpha: (1 - progress) * 0.3),
                            width: 2,
                          ),
                        ),
                      );
                    },
                  );
                }),
                Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 24, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: const Icon(Icons.mic_rounded,
                      color: Colors.white, size: 40),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const Text('Listening…',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          // Waveform
          SizedBox(
            height: 32,
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(20, (i) {
                    final phase = _waveController.value * 2 * math.pi;
                    final h = 6 + 18 * math.sin(phase + i * 0.4).abs();
                    return Container(
                      width: 3, height: h,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.primary
                            .withValues(alpha: 0.3 + 0.7 * (h / 24).clamp(0, 1)),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80, height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const Text('Translating…',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          const Text('Transcribing and translating your speech',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildResultState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badges row
          Row(
            children: [
              // Language detected badge
              if (_detectedLanguage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg, right: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.language_rounded,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        _detectedLanguage == 'English'
                            ? 'English'
                            : '$_detectedLanguage → English',
                        style: const TextStyle(fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              // Latency badge
              if (_latencyMs > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded,
                          size: 14, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text('${(_latencyMs / 1000).toStringAsFixed(1)}s',
                          style: const TextStyle(fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success)),
                    ],
                  ),
                ),
            ],
          ),

          // Original text card — labeled with the detected language
          _ResultCard(
            label: _detectedLanguage.isNotEmpty
                ? 'ORIGINAL (${_detectedLanguage.toUpperCase()})'
                : 'ORIGINAL',
            icon: Icons.record_voice_over_rounded,
            text: _originalText,
            color: AppColors.secondary,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Arrow
          const Center(
            child: Icon(Icons.arrow_downward_rounded,
                size: 28, color: AppColors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Translated text card
          _ResultCard(
            label: 'ENGLISH TRANSLATION',
            icon: Icons.translate_rounded,
            text: _translatedText,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withValues(alpha: 0.1),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 40, color: AppColors.error),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const Text('Something went wrong',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.sm),
            Text(_errorMessage,
                style: const TextStyle(fontSize: 14,
                    color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: switch (_state) {
        RecordingState.idle => PrimaryButton(
            label: 'Start Recording',
            icon: Icons.mic_rounded,
            onPressed: _startRecording,
          ),
        RecordingState.recording => PrimaryButton(
            label: 'Stop & Translate',
            icon: Icons.stop_rounded,
            onPressed: _stopAndProcess,
          ),
        RecordingState.processing => const PrimaryButton(
            label: 'Processing…',
            isLoading: true,
          ),
        RecordingState.result || RecordingState.error => Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'New Recording',
                  icon: Icons.refresh_rounded,
                  onPressed: _reset,
                ),
              ),
              if (_state == RecordingState.result) ...[
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PrimaryButton(
                    label: 'Record Again',
                    icon: Icons.mic_rounded,
                    onPressed: () {
                      _reset();
                      _startRecording();
                    },
                  ),
                ),
              ],
            ],
          ),
      },
    );
  }
}

// ─── Helper Widgets ───

class _RecordingBadge extends StatelessWidget {
  final AnimationController animation;
  const _RecordingBadge({required this.animation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              return Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: AppColors.error
                      .withValues(alpha: 0.3 + animation.value * 0.7),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          const Text('REC',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: AppColors.error, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String text;
  final Color color;

  const _ResultCard({
    required this.label,
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                      color: color, letterSpacing: 1.0)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary, height: 1.6)),
        ],
      ),
    );
  }
}
