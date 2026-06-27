import 'package:aquatrack_pro/core/constants/app_constants.dart';
import 'package:aquatrack_pro/core/utils/date_helpers.dart';

class Validators {
  Validators._();

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الاسم مطلوب';
    }
    if (value.trim().length < 2) {
      return 'الاسم يجب أن يكون 2 حروف على الأقل';
    }
    if (value.trim().length > 50) {
      return 'الاسم يجب أن لا يتجاوز 50 حرفاً';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'البريد الإلكتروني مطلوب';
    }
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');
    if (!regex.hasMatch(value.trim())) {
      return 'البريد الإلكتروني غير صحيح';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    if (value.length < 8) {
      return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
    }
    if (!value.contains(RegExp(r'[A-Z]')) && !value.contains(RegExp(r'[\u0600-\u06FF]'))) {
      return 'يجب أن تحتوي على حرف كبير أو حرف عربي واحد على الأقل';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'يجب أن تحتوي على رقم واحد على الأقل';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'تأكيد كلمة المرور مطلوب';
    }
    if (value != password) {
      return 'كلمة المرور غير متطابقة';
    }
    return null;
  }

  static String? validateBirthDate(DateTime? date) {
    if (date == null) {
      return 'تاريخ الميلاد مطلوب';
    }
    if (!DateHelpers.isInAgeRange(date)) {
      return 'العمر يجب أن يكون بين 6 و 18 سنة';
    }
    return null;
  }

  static String? validateWeight(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final weight = double.tryParse(value);
    if (weight == null) return 'الوزن يجب أن يكون رقماً';
    if (weight < AppConstants.minWeightKg || weight > AppConstants.maxWeightKg) {
      return 'الوزن يجب أن يكون بين ${AppConstants.minWeightKg} و ${AppConstants.maxWeightKg} كجم';
    }
    return null;
  }

  static String? validateHeight(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final height = double.tryParse(value);
    if (height == null) return 'الطول يجب أن يكون رقماً';
    if (height < AppConstants.minHeightCm || height > AppConstants.maxHeightCm) {
      return 'الطول يجب أن يكون بين ${AppConstants.minHeightCm} و ${AppConstants.maxHeightCm} سم';
    }
    return null;
  }

  static String? validateWeeklyHours(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final hours = double.tryParse(value);
    if (hours == null) return 'يجب أن يكون رقماً';
    if (hours < AppConstants.minWeeklyHours || hours > AppConstants.maxWeeklyHours) {
      return 'يجب أن يكون بين ${AppConstants.minWeeklyHours} و ${AppConstants.maxWeeklyHours} ساعة';
    }
    return null;
  }

  static String? validateRestingHR(int? value) {
    if (value == null) return 'نبض الراحة مطلوب';
    if (value < AppConstants.minRestingHR || value > AppConstants.maxRestingHR) {
      return 'نبض الراحة يجب أن يكون بين ${AppConstants.minRestingHR} و ${AppConstants.maxRestingHR}';
    }
    return null;
  }

  static String? validateSleepHours(double? value) {
    if (value == null) return 'ساعات النوم مطلوبة';
    if (value < AppConstants.minSleepHours || value > AppConstants.maxSleepHours) {
      return 'ساعات النوم يجب أن تكون بين ${AppConstants.minSleepHours} و ${AppConstants.maxSleepHours}';
    }
    return null;
  }

  static String? validateRPE(int? value) {
    if (value == null) return 'معدل الجهد مطلوب';
    if (value < 1 || value > AppConstants.maxRPE) {
      return 'معدل الجهد يجب أن يكون بين 1 و ${AppConstants.maxRPE}';
    }
    return null;
  }
}
