import 'package:flutter/material.dart';
import '../../domain/usecases/performance_analyzer.dart';
import '../widgets/readiness_badge.dart';

class PerformanceIntelligenceScreen extends StatelessWidget {
  final PerformanceAnalysisReport report;
  final double currentReadiness;

  const PerformanceIntelligenceScreen({
    super.key,
    required this.report,
    required this.currentReadiness,
  });

  @override
  Widget build(BuildContext context) {
    final bool isImprovement = report.timeDifference < 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Intelligence'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Current Readiness
            const Text('الجاهزية الحالية:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ReadinessBadge(readinessScore: currentReadiness),
            const Divider(height: 40),

            // Section 1: What happened?
            const Text('ماذا حدث؟', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            const SizedBox(height: 8),
            Card(
              color: isImprovement ? Colors.green.shade50 : Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      isImprovement ? Icons.trending_up : Icons.trending_down,
                      color: isImprovement ? Colors.green : Colors.red,
                      size: 40,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'زمن سباق ${report.result.eventName} ${isImprovement ? "تحسن" : "تراجع"} بمقدار ${report.timeDifference.abs().toStringAsFixed(2)} ثانية.',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Section 2: Why did it happen?
            const Text('لماذا حدث ذلك؟', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            const SizedBox(height: 8),
            ...report.reasons.map((reason) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.psychology, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(child: Text(reason, style: const TextStyle(fontSize: 16))),
                    ],
                  ),
                )),
            const SizedBox(height: 24),

            // Section 3: What to do next?
            const Text('ماذا أفعل بعد ذلك؟', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            const SizedBox(height: 8),
            ...report.nextSteps.map((step) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(child: Text(step, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
                    ],
                  ),
                )),
            const SizedBox(height: 32),

            // Section 4: Global Benchmark
            if (report.globalBenchmark != null) ...[
              const Text('التصنيف العالمي (Global Benchmark)', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
              const SizedBox(height: 8),
              Card(
                color: Colors.blue.shade50,
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('تصنيف السباح:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Chip(
                            label: Text(report.standardLevel, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            backgroundColor: Colors.blueAccent,
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('الرقم القياسي العالمي:', style: TextStyle(fontSize: 16)),
                          Text('${report.globalBenchmark!.timeSeconds} ث', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('البطل: ${report.globalBenchmark!.athleteName} (${report.globalBenchmark!.country})', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            
            // Section 5: Local Benchmark (Upper Egypt)
            if (report.localBenchmark != null && report.timeDiffToLocal != null) ...[
              const Text('رقم منطقة الصعيد (Local Benchmark)', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange)),
              const SizedBox(height: 8),
              Card(
                color: Colors.orange.shade50,
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('رقم المنطقة (الأول):', style: TextStyle(fontSize: 16)),
                          Text('${report.localBenchmark!.timeSeconds} ث', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('صاحب الرقم:', style: TextStyle(fontSize: 16)),
                          Text(report.localBenchmark!.swimmerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('الفارق الزمني بينك وبينه:', style: TextStyle(fontSize: 16)),
                          Text(
                            report.timeDiffToLocal! > 0 
                                ? '+${report.timeDiffToLocal!.toStringAsFixed(2)} ث' 
                                : '${report.timeDiffToLocal!.toStringAsFixed(2)} ث (أنت الأسرع!)', 
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.bold,
                              color: report.timeDiffToLocal! > 0 ? Colors.red : Colors.green,
                            )
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
