import 'package:flutter/material.dart';
import 'package:aquatrack_pro/core/theme/app_theme.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('سياسة الخصوصية')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section('المقدمة',
                'نحن في AquaTrack Pro نلتزم بحماية خصوصية مستخدمينا، وخاصة الأطفال. '
                'توضح هذه السياسة كيفية جمع واستخدام وحماية معلومات المستخدمين.'),
            _section('المعلومات التي نجمعها',
                '• معلومات الحساب: الاسم، البريد الإلكتروني، تاريخ الميلاد\n'
                '• معلومات المتدربين: الاسم، تاريخ الميلاد، المستوى، القياسات البدنية\n'
                '• بيانات التدريب: سجلات التدريب اليومية، النوم، التغذية، معدل الإجهاد\n'
                '• صور الملف الشخصي (اختياري)'),
            _section('كيف نستخدم المعلومات',
                '• تقديم وتحسين خدمات المتابعة الرياضية\n'
                '• تحليل أداء المتدربين وتقديم توصيات\n'
                '• إرسال تذكيرات وإشعارات\n'
                '• دعم فني وتحسين التطبيق'),
            _section('خصوصية الأطفال (COPPA)',
                'نلتزم بقانون حماية خصوصية الأطفال على الإنترنت (COPPA). '
                'نحن لا نجمع معلومات شخصية من الأطفال دون سن 13 عاماً بدون موافقة الوالدين. '
                'يمكن للوالدين طلب مراجعة أو حذف معلومات أطفالهم في أي وقت.'),
            _section('مشاركة المعلومات',
                'لا نشارك معلومات المستخدمين مع أطراف ثالثة للأغراض التسويقية. '
                'قد نشارك معلومات مجمعة غير شخصية لأغراض البحث والتحليل.'),
            _section('حماية المعلومات',
                'نستخدم إجراءات أمنية مناسبة لحماية معلومات المستخدمين من الوصول غير المصرح به أو التعديل أو الإفصاح.'),
            _section('حقوق المستخدم',
                '• الحق في الوصول إلى معلوماتك\n'
                '• الحق في تصحيح أو تحديث معلوماتك\n'
                '• الحق في حذف معلوماتك\n'
                '• الحق في سحب الموافقة في أي وقت'),
            _section('اتصل بنا',
                'للاستفسار عن سياسة الخصوصية: support@aquatrackpro.com'),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
          const SizedBox(height: 8),
          Text(body,
              style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
