import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aquatrack_pro/core/theme/app_theme.dart';
import 'package:aquatrack_pro/features/swim_vision/presentation/screens/camera_record_screen.dart';
import 'package:aquatrack_pro/features/swim_vision/presentation/screens/processing_screen.dart';
import 'package:aquatrack_pro/features/swim_vision/presentation/screens/race_speed_input_screen.dart';

class SwimVisionScreen extends StatelessWidget {
  final String userId;
  final String athleteId;

  const SwimVisionScreen({
    super.key,
    required this.userId,
    required this.athleteId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحليل السباحة'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اختر طريقة التحليل',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'صوّر سباحاً أو اختر فيديو من هاتفك للتحليل بالذكاء الاصطناعي',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            _OptionCard(
              icon: Icons.videocam_rounded,
              title: 'تصوير فيديو جديد',
              subtitle: 'افتح الكاميرا وصوّر السباح',
              color: AppColors.accent,
              onTap: () => _openCamera(context),
            ),
            const SizedBox(height: 12),
            _OptionCard(
              icon: Icons.photo_library_outlined,
              title: 'اختر من المعرض',
              subtitle: 'حمّل فيديو موجود على هاتفك',
              color: AppColors.primary,
              onTap: () => _pickFromGallery(context),
            ),
            const SizedBox(height: 12),
            _OptionCard(
              icon: Icons.speed_rounded,
              title: 'تحليل سرعة السباق',
              subtitle: 'أدخل أزمان السباق لمعرفة منحنى الهبوط',
              color: Colors.deepPurple,
              onTap: () => _openRaceSpeed(context),
            ),
            const SizedBox(height: 12),
            _OptionCard(
              icon: Icons.tips_and_updates_outlined,
              title: 'نصائح التصوير الصحيح',
              subtitle: 'كيف تصوّر لتحصل على أفضل تحليل',
              color: AppColors.info,
              onTap: () => _showTips(context),
            ),
          ],
        ),
      ),
    );
  }

  void _openCamera(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CameraRecordScreen(
          onVideoCaptured: (file) {
            Navigator.pop(context);
            _startProcessing(context, file);
          },
        ),
      ),
    );
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final video = await picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        final file = File(video.path);
        if (context.mounted) {
          _startProcessing(context, file);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل اختيار الفيديو: $e')),
        );
      }
    }
  }

  void _startProcessing(BuildContext context, File videoFile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProcessingScreen(
          videoFile: videoFile,
          userId: userId,
          athleteId: athleteId,
        ),
      ),
    );
  }

  void _openRaceSpeed(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RaceSpeedInputScreen(
          userId: userId,
          athleteId: athleteId,
        ),
      ),
    );
  }

  void _showTips(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📹 نصائح للتصوير المثالي',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 16),
            _TipItem(icon: '1️⃣', text: 'صوّر من الجانب (side view) للحصول على أفضل تحليل'),
            SizedBox(height: 8),
            _TipItem(icon: '2️⃣', text: 'تأكد أن جسم السباح كامل داخل الكادر'),
            SizedBox(height: 8),
            _TipItem(icon: '3️⃣', text: 'الإضاءة الجيدة مهمة — تجنب التصوير ضد الشمس'),
            SizedBox(height: 8),
            _TipItem(icon: '4️⃣', text: 'المدة المثالية: 15–30 ثانية'),
            SizedBox(height: 8),
            _TipItem(icon: '5️⃣', text: 'ثبّت الهاتف أو استخدم حامل للحصول على فيديو واضح'),
            SizedBox(height: 8),
            _TipItem(icon: '6️⃣', text: 'أفضل زاوية: 90 درجة من جانب حوض السباحة'),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_left, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final String icon;
  final String text;

  const _TipItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
