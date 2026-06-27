import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/nutrition_bloc.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/entities/meal_log.dart';

class AddMealScreen extends StatefulWidget {
  final String athleteId;
  final DateTime date;
  final MealType mealType;

  const AddMealScreen({super.key, required this.athleteId, required this.date, required this.mealType});

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  String _searchQuery = '';
  FoodItem? _selectedFood;
  final _amountController = TextEditingController(text: '100');

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _saveMeal() {
    if (_selectedFood == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار صنف طعام')));
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال كمية صحيحة بالجرام')));
      return;
    }

    context.read<NutritionBloc>().add(AddMealEntryEvent(
          athleteId: widget.athleteId,
          date: widget.date,
          type: widget.mealType,
          food: _selectedFood!,
          amountInGrams: amount,
        ));

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة طعام')),
      body: BlocBuilder<NutritionBloc, NutritionState>(
        builder: (context, state) {
          final foods = state.foodDatabase.where((f) {
            return f.nameAr.contains(_searchQuery) || f.nameEn.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'بحث عن طعام...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 16),
                if (_selectedFood != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Column(
                      children: [
                        Text('تم اختيار: ${_selectedFood!.nameAr}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('الكمية (جرام): '),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: foods.length,
                    itemBuilder: (context, index) {
                      final f = foods[index];
                      return ListTile(
                        leading: _getCategoryIcon(f.category),
                        title: Text(f.nameAr),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${f.calories} kcal | P: ${f.proteinG}g | C: ${f.carbsG}g | F: ${f.fatG}g'),
                            if (f.notesAr.isNotEmpty)
                              Text(f.notesAr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            if (f.climate != 'any')
                              Text(
                                f.climate == 'hot' ? '🔥 الأجواء الحارة' : '❄️ الأجواء الباردة',
                                style: TextStyle(fontSize: 12, color: f.climate == 'hot' ? Colors.red : Colors.blue),
                              ),
                          ],
                        ),
                        trailing: _selectedFood?.id == f.id
                            ? const Icon(Icons.check_circle, color: Colors.blue)
                            : const Icon(Icons.add_circle_outline),
                        onTap: () => setState(() => _selectedFood = f),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveMeal,
                    child: const Text('حفظ الوجبة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _getCategoryIcon(String category) {
    switch (category) {
      case 'Breakfast': return const Icon(Icons.wb_sunny, color: Colors.orange);
      case 'Lunch': return const Icon(Icons.restaurant, color: Colors.brown);
      case 'Dinner': return const Icon(Icons.dark_mode, color: Colors.indigo);
      case 'Snacks': return const Icon(Icons.cookie, color: Colors.purple);
      case 'Pre-Workout': return const Icon(Icons.bolt, color: Colors.amber);
      case 'Intra-Workout': return const Icon(Icons.loop, color: Colors.blue);
      case 'Post-Workout': return const Icon(Icons.fitness_center, color: Colors.red);
      case 'Hydration': return const Icon(Icons.water_drop, color: Colors.lightBlue);
      default: return const Icon(Icons.restaurant_menu, color: Colors.grey);
    }
  }
}
