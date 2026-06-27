import 'dart:math' as math;
import 'dart:convert';

/// Represents a single segment in the speed dynamics analysis.
class SpeedSegment {
  final String range;
  final double time;
  final double speed;
  final double speedChangePercent;

  const SpeedSegment({
    required this.range,
    required this.time,
    required this.speed,
    required this.speedChangePercent,
  });

  Map<String, dynamic> toJson() => {
        'range': range,
        'time': time,
        'speed': speed,
        'speed_change_percent': speedChangePercent,
      };
}

/// Represents the global metrics for the speed dynamics.
class SpeedMetrics {
  final double maxSpeed;
  final double averageSpeed;
  final double minSpeed;
  final double totalSpeedDropPercent;
  final double speedVariance;
  final double fatigueIndex;

  const SpeedMetrics({
    required this.maxSpeed,
    required this.averageSpeed,
    required this.minSpeed,
    required this.totalSpeedDropPercent,
    required this.speedVariance,
    required this.fatigueIndex,
  });

  Map<String, dynamic> toJson() => {
        'max_speed': maxSpeed,
        'average_speed': averageSpeed,
        'min_speed': minSpeed,
        'total_speed_drop_percent': totalSpeedDropPercent,
        'speed_variance': speedVariance,
        'fatigue_index': fatigueIndex,
      };
}

/// The result of the Universal Speed Dynamics Analysis.
class UniversalSpeedAnalysisResult {
  final double segmentSizeM;
  final List<SpeedSegment> segments;
  final SpeedMetrics metrics;
  final String classification;
  final List<String> insights;

  const UniversalSpeedAnalysisResult({
    required this.segmentSizeM,
    required this.segments,
    required this.metrics,
    required this.classification,
    required this.insights,
  });

  Map<String, dynamic> toJson() => {
        'universal_speed_analysis': {
          'segment_size_m': segmentSizeM,
          'segments': segments.map((s) => s.toJson()).toList(),
          'metrics': metrics.toJson(),
          'classification': classification,
          'insights': insights,
        }
      };
      
  String toJsonString() => jsonEncode(toJson());
}

/// A standalone module to analyze swimming speed drop across any race distance.
/// This module adheres strictly to the biomechanical rules of speed dynamics
/// and produces a formatted JSON output.
class UniversalSpeedDynamicsModule {
  /// Analyzes the race based on cumulative split times.
  /// [totalDistance] The total distance of the race in meters (e.g., 50, 100, 200).
  /// [cumulativeSplits] A list of cumulative times in seconds at each segment point.
  UniversalSpeedAnalysisResult analyzeRace({
    required double totalDistance,
    required List<double> cumulativeSplits,
  }) {
    if (cumulativeSplits.isEmpty) {
      return _insufficientData(totalDistance);
    }

    final segmentCount = cumulativeSplits.length;
    final segmentSizeM = totalDistance / segmentCount;
    
    // Check if we need to fallback based on the rules. 
    // If input is less than 5 splits for a 50m (which means >10m per segment), we accept the input's resolution.
    // The preferred is 10m, fallback is 20m or whatever is provided.
    
    if (segmentCount < 2) {
      return _insufficientData(segmentSizeM);
    }

    final segments = <SpeedSegment>[];
    double previousSpeed = 0.0;
    double previousTime = 0.0;
    
    double sumSpeed = 0.0;
    double maxSpeed = -double.infinity;
    double minSpeed = double.infinity;

    for (int i = 0; i < segmentCount; i++) {
      final currentCumulativeTime = cumulativeSplits[i];
      final segmentTime = currentCumulativeTime - previousTime;
      
      if (segmentTime <= 0) continue; // Prevent division by zero or invalid negative splits

      final speed = segmentSizeM / segmentTime;
      
      double speedChangePercent = 0.0;
      if (i > 0 && previousSpeed > 0) {
        speedChangePercent = ((speed - previousSpeed) / previousSpeed) * 100;
      }

      final startM = i * segmentSizeM;
      final endM = (i + 1) * segmentSizeM;
      
      segments.add(SpeedSegment(
        range: '${startM.toStringAsFixed(0)}-${endM.toStringAsFixed(0)}m',
        time: double.parse(segmentTime.toStringAsFixed(2)),
        speed: double.parse(speed.toStringAsFixed(2)),
        speedChangePercent: double.parse(speedChangePercent.toStringAsFixed(2)),
      ));

      sumSpeed += speed;
      if (speed > maxSpeed) maxSpeed = speed;
      if (speed < minSpeed) minSpeed = speed;

      previousSpeed = speed;
      previousTime = currentCumulativeTime;
    }

    if (segments.isEmpty) {
      return _insufficientData(segmentSizeM);
    }

    final averageSpeed = sumSpeed / segments.length;
    
    // Variance calculation
    double sumSquaredDiff = 0.0;
    for (final s in segments) {
      sumSquaredDiff += math.pow(s.speed - averageSpeed, 2);
    }
    final speedVariance = sumSquaredDiff / segments.length;

    // Total speed drop percent from max to last segment
    final lastSpeed = segments.last.speed;
    double totalSpeedDropPercent = 0.0;
    if (maxSpeed > 0) {
      totalSpeedDropPercent = ((maxSpeed - lastSpeed) / maxSpeed) * 100;
    }

    // Fatigue index (trend slope of speed over distance)
    // using simple linear regression: slope = Σ((x - x_mean) * (y - y_mean)) / Σ((x - x_mean)^2)
    double sumX = 0.0;
    double sumY = 0.0;
    for (int i = 0; i < segments.length; i++) {
      sumX += i;
      sumY += segments[i].speed;
    }
    final xMean = sumX / segments.length;
    final yMean = sumY / segments.length;
    
    double num = 0.0;
    double den = 0.0;
    for (int i = 0; i < segments.length; i++) {
      num += (i - xMean) * (segments[i].speed - yMean);
      den += math.pow(i - xMean, 2);
    }
    final fatigueIndex = den == 0 ? 0.0 : (num / den); // slope of speed per segment

    final metrics = SpeedMetrics(
      maxSpeed: double.parse(maxSpeed.toStringAsFixed(2)),
      averageSpeed: double.parse(averageSpeed.toStringAsFixed(2)),
      minSpeed: double.parse(minSpeed.toStringAsFixed(2)),
      totalSpeedDropPercent: double.parse(totalSpeedDropPercent.toStringAsFixed(2)),
      speedVariance: double.parse(speedVariance.toStringAsFixed(4)),
      fatigueIndex: double.parse(fatigueIndex.toStringAsFixed(4)),
    );

    final classification = _classifyPattern(metrics, segments);
    final insights = _generateInsights(classification, metrics);

    return UniversalSpeedAnalysisResult(
      segmentSizeM: double.parse(segmentSizeM.toStringAsFixed(1)),
      segments: segments,
      metrics: metrics,
      classification: classification,
      insights: insights,
    );
  }

  String _classifyPattern(SpeedMetrics metrics, List<SpeedSegment> segments) {
    if (segments.length < 2) return 'insufficient_data';

    // Positive split: Speed increases in the second half.
    // Meaning the slope (fatigue index) is positive and significant.
    if (metrics.fatigueIndex > 0.02) {
      return 'positive_split';
    }

    // Sprint drop: High initial speed, sharp decline early on.
    if (segments.length >= 3 && segments.first.speed == metrics.maxSpeed) {
      if (segments[1].speedChangePercent < -5.0 && metrics.totalSpeedDropPercent > 10.0) {
        return 'sprint_drop';
      }
    }

    // Negative split fatigue: Speed slows down significantly.
    // Meaning total speed drop is high or negative slope is steep.
    if (metrics.totalSpeedDropPercent > 15.0 || metrics.fatigueIndex < -0.05) {
      return 'negative_split_fatigue';
    }

    // Stable pacer: Low variance, steady speed.
    if (metrics.speedVariance < 0.1 && metrics.totalSpeedDropPercent <= 10.0) {
      return 'stable_pacer';
    }

    // Default catch-all for mild fatigue
    return 'negative_split_fatigue';
  }

  List<String> _generateInsights(String classification, SpeedMetrics metrics) {
    switch (classification) {
      case 'stable_pacer':
        return [
          'تنظيم جهد (Pacing) مستقر للغاية يوضح كفاءة تحمل هوائي ممتازة.',
          'استهلاك طاقة متوازن يقلل من تدهور التكنيك في الأمتار الأخيرة.'
        ];
      case 'positive_split':
        return [
          'استراتيجية تقسيم إيجابي: السباق انتهى بسرعة أعلى من البداية.',
          'يوجد فائض في الطاقة قد يعني إمكانية زيادة السرعة الأساسية (Base Speed) في النصف الأول.'
        ];
      case 'negative_split_fatigue':
        return [
          'تدهور ملحوظ في السرعة يشير إلى تراكم حمض اللاكتيك وإجهاد عضلي.',
          'ينصح بالتركيز على تدريبات تحمل السرعة (Speed Endurance) لتقليل نسبة هبوط الأداء (${metrics.totalSpeedDropPercent}%).'
        ];
      case 'sprint_drop':
        return [
          'انطلاقة انفجارية تلاها هبوط حاد في السرعة.',
          'استنفاد سريع لنظام الطاقة اللاهوائي (ATP-PC)، يتطلب موازنة السرعة الابتدائية وتطوير القدرة اللاهوائية.'
        ];
      default:
        return [
          'البيانات غير كافية لتقديم تحليل حركي دقيق لمسار السرعة.',
        ];
    }
  }

  UniversalSpeedAnalysisResult _insufficientData(double segmentSize) {
    return UniversalSpeedAnalysisResult(
      segmentSizeM: segmentSize,
      segments: [],
      metrics: const SpeedMetrics(
        maxSpeed: 0.0,
        averageSpeed: 0.0,
        minSpeed: 0.0,
        totalSpeedDropPercent: 0.0,
        speedVariance: 0.0,
        fatigueIndex: 0.0,
      ),
      classification: 'insufficient_data',
      insights: ['البيانات غير كافية لإجراء التحليل (تحتاج مقطعين على الأقل).'],
    );
  }
}
