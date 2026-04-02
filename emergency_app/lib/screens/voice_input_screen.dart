import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../services/translation_api_service.dart';
import 'patient_summary_screen.dart';

/// Screen 2: Voice Input (Listening)
/// Center microphone, listening animation, real translation, Retry/Confirm buttons.
class VoiceInputScreen extends StatefulWidget {
  const VoiceInputScreen({super.key});

  @override
  State<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

enum VoiceInputState { idle, recording, processing, result, error }

class _VoiceInputScreenState extends State<VoiceInputScreen>
    with TickerProviderStateMixin {
  late AnimationController _rippleController;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  final AudioRecorder _recorder = AudioRecorder();
  VoiceInputState _state = VoiceInputState.idle;
  String _translatedText = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _recorder.dispose();
    _rippleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        setState(() {
          _state = VoiceInputState.error;
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
        path: path ?? '',
      );

      setState(() => _state = VoiceInputState.recording);
      _rippleController.repeat();
      _glowController.repeat(reverse: true);
    } catch (e) {
      setState(() {
        _state = VoiceInputState.error;
        _errorMessage = 'Failed to start recording: $e';
      });
    }
  }

  Future<void> _stopAndProcess() async {
    try {
      final path = await _recorder.stop();
      _rippleController.stop();
      _glowController.stop();

      if (path == null) {
        setState(() {
          _state = VoiceInputState.error;
          _errorMessage = 'No recording found';
        });
        return;
      }

      setState(() => _state = VoiceInputState.processing);

      final result = await TranslationApiService.transcribeAudio(path);

      setState(() {
        _state = VoiceInputState.result;
        _translatedText = result['translated'] ?? '';
      });
    } catch (e) {
      setState(() {
        _state = VoiceInputState.error;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _reset() {
    setState(() {
      _state = VoiceInputState.idle;
      _translatedText = '';
      _errorMessage = '';
    });
    _rippleController.stop();
    _glowController.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.lg),

              // ─── Top bar ───
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Voice Input',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Describe the emergency',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Recording indicator
                  if (_state == VoiceInputState.recording || _state == VoiceInputState.idle)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: _glowAnimation,
                            builder: (context, _) {
                              return Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.error
                                      .withValues(alpha: _state == VoiceInputState.recording ? _glowAnimation.value : 0.3),
                                  shape: BoxShape.circle,
                                  boxShadow: _state == VoiceInputState.recording ? [
                                    BoxShadow(
                                      color: AppColors.error.withValues(
                                          alpha: _glowAnimation.value * 0.5),
                                      blurRadius: 6,
                                    ),
                                  ] : null,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'REC',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              // ─── Microphone with ripple animation ───
              const Spacer(flex: 2),
              GestureDetector(
                onTap: () {
                  if (_state == VoiceInputState.idle) {
                    _startRecording();
                  } else if (_state == VoiceInputState.recording) {
                    _stopAndProcess();
                  }
                },
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ripple rings
                      if (_state == VoiceInputState.recording)
                        ...List.generate(3, (index) {
                          return AnimatedBuilder(
                            animation: _rippleController,
                            builder: (context, _) {
                              final progress = ((_rippleController.value +
                                          index * 0.33) %
                                      1.0);
                              return Container(
                                width: 120 + (progress * 100),
                                height: 120 + (progress * 100),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary.withValues(
                                        alpha: (1 - progress) * 0.25),
                                    width: 2,
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                      // Glow background
                      if (_state == VoiceInputState.recording)
                        AnimatedBuilder(
                          animation: _glowAnimation,
                          builder: (context, child) {
                            return Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.primary
                                        .withValues(alpha: _glowAnimation.value),
                                    AppColors.primary.withValues(alpha: 0.0),
                                  ],
                                  stops: const [0.5, 1.0],
                                ),
                              ),
                            );
                          },
                        ),
                      // Mic button
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primary, AppColors.primaryDark],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          _state == VoiceInputState.recording ? Icons.stop_rounded : Icons.mic_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ─── Status text ───
              Text(
                _state == VoiceInputState.idle ? 'Tap Mic to Speak' : 
                _state == VoiceInputState.recording ? 'Listening… (Tap to Stop)' :
                _state == VoiceInputState.processing ? 'Translating…' :
                _state == VoiceInputState.error ? 'Error' : 'Complete',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // ─── Visualizer / Error message ───
              if (_state == VoiceInputState.recording)
                SizedBox(
                  height: 40,
                  child: AnimatedBuilder(
                    animation: _rippleController,
                    builder: (context, _) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(24, (index) {
                          final phase = _rippleController.value * 2 * math.pi;
                          final height = 8 +
                              20 *
                                  math.sin(phase + index * 0.4).abs() *
                                  (0.4 + 0.6 * math.sin(phase + index * 0.2).abs());
                          return Container(
                            width: 3,
                            height: height,
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(
                                  alpha: 0.3 + 0.7 * (height / 28).clamp(0, 1)),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                )
              else if (_state == VoiceInputState.processing)
                SizedBox(
                  height: 40,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                )
              else if (_state == VoiceInputState.error)
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error, fontSize: 14),
                )
              else
                const SizedBox(height: 40),
                
              const SizedBox(height: AppSpacing.xxl),

              // ─── Transcription card ───
              if (_state == VoiceInputState.result)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: AppShadows.card,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.text_snippet_rounded,
                            size: 16,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'TRANSLATION',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textTertiary,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _translatedText.isNotEmpty ? '\"$_translatedText\"' : 'No speech detected.',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textPrimary,
                          height: 1.6,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

              const Spacer(flex: 2),

              // ─── Action buttons ───
              if (_state == VoiceInputState.result || _state == VoiceInputState.error)
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: 'Retry',
                        icon: Icons.refresh_rounded,
                        onPressed: _reset,
                      ),
                    ),
                    if (_state == VoiceInputState.result) ...[
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Confirm',
                          icon: Icons.check_rounded,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PatientSummaryScreen(
                                  additionalNotes: _translatedText,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
