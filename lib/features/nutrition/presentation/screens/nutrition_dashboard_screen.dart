import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../bloc/nutrition_bloc.dart';
import '../../domain/entities/meal_log.dart';
import 'add_meal_screen.dart';
import 'package:aquatrack_pro/features/athlete/domain/entities/athlete_entity.dart';

class NutritionDashboardScreen extends StatefulWidget {
  final AthleteEntity athlete;

  const NutritionDashboardScreen({super.key, required this.athlete});

  @override
  State<NutritionDashboardScreen> createState() => _NutritionDashboardScreenState();
}

class _NutritionDashboardScreenState extends State<NutritionDashboardScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    context.read<NutritionBloc>().add(
          LoadNutritionData(athlete: widget.athlete, date: _selectedDate),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التغذية والتعافي', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
                _loadData();
              }
            },
          )
        ],
      ),
      body: BlocBuilder<NutritionBloc, NutritionState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null) {
            return Center(child: Text('حدث خطأ: ${state.error}'));
          }

          final calsLeft = state.targetTDEE - state.consumedCalories;

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(state, calsLeft),
                  const SizedBox(height: 24),
                  _buildHydrationTracker(context, state),
                  const SizedBox(height: 24),
                  _buildAiCoachCard(context),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('سجل الوجبات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('نسخ الأمس'),
                        onPressed: () {
                          context.read<NutritionBloc>().add(
                            CopyYesterdayMealsEvent(athleteId: widget.athlete.id, todayDate: _selectedDate)
                          );
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ وجبات الأمس بنجاح')));
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...MealType.values.map((type) => _buildMealCard(context, state, type)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(NutritionState state, double calsLeft) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMacroProgress('كاربوهيدرات', state.consumedCarbs, state.targetMacros['carbsG'] ?? 0, Colors.orange),
              SizedBox(
                height: 140,
                width: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 0,
                        centerSpaceRadius: 50,
                        startDegreeOffset: -90,
                        sections: [
                          PieChartSectionData(
                            color: Colors.blue,
                            value: state.consumedCalories,
                            title: '',
                            radius: 12,
                          ),
                          PieChartSectionData(
                            color: Colors.grey.withAlpha(50),
                            value: calsLeft > 0 ? calsLeft : 0,
                            title: '',
                            radius: 12,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${calsLeft > 0 ? calsLeft.toInt() : 0}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const Text('متبقي kcal', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    )
                  ],
                ),
              ),
              _buildMacroProgress('بروتين', state.consumedProtein, state.targetMacros['proteinG'] ?? 0, Colors.green),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               _buildMacroProgress('دهون', state.consumedFat, state.targetMacros['fatG'] ?? 0, Colors.redAccent),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHydrationTracker(BuildContext context, NutritionState state) {
    const double goalLiters = 3.0; // Dynamic based on athlete later
    final double percent = (state.currentHydration / goalLiters).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade400, Colors.cyan.shade600]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الترطيب (Hydration)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          Text('${state.currentHydration.toStringAsFixed(1)} L / $goalLiters L', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 12,
              backgroundColor: Colors.white.withAlpha(80),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildWaterButton(context, state, '+250 مل', 0.25),
              _buildWaterButton(context, state, '+500 مل', 0.50),
              _buildWaterButton(context, state, '+1 لتر', 1.0),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildWaterButton(BuildContext context, NutritionState state, String label, double amount) {
    return ElevatedButton(
      onPressed: () {
        context.read<NutritionBloc>().add(UpdateHydrationEvent(
          athleteId: widget.athlete.id,
          date: _selectedDate,
          liters: state.currentHydration + amount,
        ));
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withAlpha(50),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      child: Text(label),
    );
  }

  Widget _buildMacroProgress(String label, double consumed, double target, Color color) {
    double percent = target > 0 ? consumed / target : 0;
    if (percent > 1) percent = 1;
    
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        SizedBox(
          height: 60,
          width: 60,
          child: CircularProgressIndicator(
            value: percent,
            color: color,
            backgroundColor: color.withAlpha(50),
            strokeWidth: 8,
          ),
        ),
        const SizedBox(height: 8),
        Text('${consumed.toInt()} / ${target.toInt()}g', style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildAiCoachCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.purple.shade700, Colors.blue.shade700]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('المدرب التغذوي AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text('اضغط للحصول على تحليل تغذوي بناءً على سباقاتك اليوم.', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سيتم تفعيل المدرب لاحقاً بناءً على قراءات السرعة')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.purple.shade700),
            child: const Text('تحليل'),
          )
        ],
      ),
    );
  }

  Widget _buildMealCard(BuildContext context, NutritionState state, MealType type) {
    final logIndex = state.dailyLogs.indexWhere((l) => l.mealType == type);
    final log = logIndex >= 0 ? state.dailyLogs[logIndex] : null;
    
    final String title = _getMealTitle(type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${log?.totalCalories.toInt() ?? 0} kcal', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            if (log != null && log.entries.isNotEmpty)
              ...log.entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${e.food.nameAr} (${e.amountInGrams.toInt()}g)'),
                        Text('${e.calories.toInt()} kcal', style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )),
            if (log == null || log.entries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('لم يتم تسجيل أصناف.', style: TextStyle(color: Colors.grey)),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _navigateToAddMeal(context, type),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('إضافة طعام'),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _navigateToAddMeal(BuildContext context, MealType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<NutritionBloc>(),
          child: AddMealScreen(athleteId: widget.athlete.id, date: _selectedDate, mealType: type),
        ),
      ),
    );
  }

  String _getMealTitle(MealType type) {
    switch (type) {
      case MealType.breakfast: return 'الإفطار';
      case MealType.lunch: return 'الغداء';
      case MealType.dinner: return 'العشاء';
      case MealType.snack: return 'وجبة خفيفة';
      case MealType.preWorkout: return 'قبل التمرين';
      case MealType.postWorkout: return 'بعد التمرين (Recovery)';
    }
  }
}
