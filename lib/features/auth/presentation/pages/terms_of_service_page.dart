import 'package:flutter/material.dart';
import 'package:aquatrack_pro/core/theme/app_theme.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('شروط الاستخدام')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section('القبول بالشروط',
                'باستخدام تطبيق AquaTrack Pro، فإنك توافق على هذه الشروط. إذا كنت ولي أمر طفل دون 18 سنة، '
                'فأنت توافق نيابة عنه.'),
            _section('الوصف',
                'هذا التطبيق مخصص لمساعدة المدربين وأولياء الأمور في متابعة أداء السباحين الصغار '
                'من خلال تسجيل البيانات اليومية وتحليل المؤشرات الرياضية.'),
            _section('المسؤوليات',
                '• تقديم معلومات دقيقة عند التسجيل\n'
                '• المحافظة على سرية معلومات الحساب\n'
                '• استخدام التطبيق بطريقة قانونية ومناسبة\n'
                '• عدم إساءة استخدام النظام أو محاولة اختراقه'),
            _section('البيانات',
                'جميع البيانات المدخلة مملوكة للمستخدم. نحن لا نبيع أو نشارك البيانات الشخصية مع أطراف ثالثة.'),
            _section('الإلغاء',
                'يمكنك حذف حسابك وبياناتك في أي وقت من خلال الإعدادات. '
                'نحتفظ بالحق في إنهاء الحسابات المخالفة للشروط.'),
            _section('تحديث الشروط',
                'قد نقوم بتحديث هذه الشروط من وقت لآخر. سيتم إشعارك بالتغييرات المهمة عبر البريد الإلكتروني أو الإشعارات.'),
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
