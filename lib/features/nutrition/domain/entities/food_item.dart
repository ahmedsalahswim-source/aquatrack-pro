import 'package:equatable/equatable.dart';

class FoodItem extends Equatable {
  final String id;
  final String nameAr;
  final String nameEn;
  final String category;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final String notesAr;
  final String climate;

  const FoodItem({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.category,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.notesAr,
    required this.climate,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] as String,
      nameAr: json['nameAr'] as String,
      nameEn: json['nameEn'] as String,
      category: json['category'] as String,
      calories: (json['macros']['calories'] as num).toDouble(),
      proteinG: (json['macros']['protein'] as num).toDouble(),
      carbsG: (json['macros']['carbs'] as num).toDouble(),
      fatG: (json['macros']['fats'] as num).toDouble(),
      notesAr: json['notesAr'] as String? ?? '',
      climate: json['climate'] as String? ?? 'any',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'category': category,
      'macros': {
        'calories': calories,
        'protein': proteinG,
        'carbs': carbsG,
        'fats': fatG,
      },
      'notesAr': notesAr,
      'climate': climate,
    };
  }

  @override
  List<Object?> get props => [
        id,
        nameAr,
        nameEn,
        category,
        calories,
        proteinG,
        carbsG,
        fatG,
        notesAr,
        climate,
      ];
}
