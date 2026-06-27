import 'package:flutter/material.dart';
import 'package:aquatrack_pro/core/theme/app_theme.dart';
import 'package:aquatrack_pro/features/swim_vision/presentation/screens/race_speed_result_screen.dart';

class RaceSpeedInputScreen extends StatefulWidget {
  final String userId;
  final String athleteId;

  const RaceSpeedInputScreen({
    super.key,
    required this.userId,
    required this.athleteId,
  });

  @override
  State<RaceSpeedInputScreen> createState() => _RaceSpeedInputScreenState();
}

class _RaceSpeedInputScreenState extends State<RaceSpeedInputScreen> {
  int _totalDistance = 50;
  int _segmentDistance = 10;
  final List<TextEditingController> _controllers = [];
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _rebuildControllers();
  }

  void _rebuildControllers() {
    for (var c in _controllers) {
      c.dispose();
    }
    _controllers.clear();
    int segments = (_totalDistance / _segmentDistance).ceil();
    for (int i = 0; i < segments; i++) {
      _controllers.add(TextEditingController());
    }
    setState(() {});
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onDistanceChanged(int? newDist) {
    if (newDist != null) {
      setState(() {
        _totalDistance = newDist;
        if (_segmentDistance > newDist) {
          _segmentDistance = newDist == 50 ? 10 : 25;
        }
      });
      _rebuildControllers();
    }
  }

  void _onSegmentChanged(int? newSeg) {
    if (newSeg != null) {
      setState(() {
        _segmentDistance = newSeg;
      });
      _rebuildControllers();
    }
  }

  void _analyze() {
    if (!_formKey.currentState!.validate()) return;

    List<double> cumulativeSplits = [];
    double previousTime = 0.0;

    for (int i = 0; i < _controllers.length; i++) {
      double? time = double.tryParse(_controllers[i].text.trim());
      if (time == null) return; // Handled by validator
      if (time <= previousTime) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يجب أن تكون الأزمان التراكمية متزايدة')),
        );
        return;
      }
      cumulativeSplits.add(time);
      previousTime = time;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RaceSpeedResultScreen(
          totalDistance: _totalDistance.toDouble(),
          cumulativeSplits: cumulativeSplits,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int segments = (_totalDistance / _segmentDistance).ceil();

    return Scaffold(
      appBar: AppBar(
        title: const Text('تحليل سرعة السباق'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'إعدادات السباق',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'المسافة الكلية (متر)',
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _totalDistance,
                        isDense: true,
                        items: const [
                          DropdownMenuItem(value: 50, child: Text('50 متر')),
                          DropdownMenuItem(value: 100, child: Text('100 متر')),
                          DropdownMenuItem(value: 200, child: Text('200 متر')),
                          DropdownMenuItem(value: 400, child: Text('400 متر')),
                        ],
                        onChanged: _onDistanceChanged,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'طول المقطع (متر)',
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _segmentDistance,
                        isDense: true,
                        items: [
                          if (_totalDistance >= 50)
                            const DropdownMenuItem(value: 10, child: Text('10 متر')),
                          if (_totalDistance >= 25)
                            const DropdownMenuItem(value: 25, child: Text('25 متر')),
                          if (_totalDistance >= 50)
                            const DropdownMenuItem(value: 50, child: Text('50 متر')),
                          if (_totalDistance >= 100)
                            const DropdownMenuItem(value: 100, child: Text('100 متر')),
                        ],
                        onChanged: _onSegmentChanged,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'الأزمان التراكمية (ثواني)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'أدخل الزمن الذي وصل إليه السباح عند كل مقطع.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ...List.generate(segments, (index) {
              int currentDist = (index + 1) * _segmentDistance;
              if (currentDist > _totalDistance) currentDist = _totalDistance;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: _controllers[index],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'عند $currentDist متر',
                    hintText: 'مثال: ${currentDist * 0.6}',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.timer_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'مطلوب';
                    }
                    if (double.tryParse(value.trim()) == null) {
                      return 'رقم غير صحيح';
                    }
                    return null;
                  },
                ),
              );
            }),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _analyze,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: const Text('تحليل الأداء'),
            ),
          ],
        ),
      ),
    );
  }
}
