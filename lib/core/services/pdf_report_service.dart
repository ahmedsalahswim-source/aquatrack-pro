import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:aquatrack_pro/features/athlete/domain/entities/athlete_entity.dart';
import 'package:aquatrack_pro/features/daily_log/domain/entities/daily_log_entity.dart';

class PdfReportService {
  PdfReportService._();

  static Future<Uint8List> generateAthleteReport({
    required AthleteEntity athlete,
    required List<DailyLogEntity> logs,
    int days = 7,
    DateTime? now,
  }) {
    final pdf = pw.Document();
    final effectiveNow = now ?? DateTime.now();
    final fromDate = effectiveNow.subtract(Duration(days: days - 1));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(athlete, fromDate, effectiveNow, days),
          pw.SizedBox(height: 20),
          _buildAthleteInfo(athlete, effectiveNow),
          pw.SizedBox(height: 20),
          _buildSummarySection(logs),
          pw.SizedBox(height: 20),
          _buildBarChart(logs),
          pw.SizedBox(height: 20),
          _buildLogsTable(logs),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(AthleteEntity athlete, DateTime from, DateTime to, int days) {
    final df = DateFormat('yyyy/MM/dd');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('AquaTrack Pro', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
            pw.Text('تقرير المتدرب', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Text('الفترة: ${df.format(from)} - ${df.format(to)}  |  $days أيام',
            style: pw.TextStyle(fontSize: 11, color: PdfColors.grey)),
        pw.Divider(),
      ],
    );
  }

  static pw.Widget _buildAthleteInfo(AthleteEntity athlete, [DateTime? now]) {
    final ref = now ?? DateTime.now();
    final age = ref.difference(athlete.birthDate).inDays ~/ 365;
    return pw.Container(
      padding: pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(athlete.name, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          _infoRow('العمر', '$age سنة'),
          _infoRow('المستوى', _swimLevelLabel(athlete.swimLevel)),
          _infoRow('الجنس', athlete.gender.name == 'male' ? 'ذكر' : 'أنثى'),
          if (athlete.weightKg != null) _infoRow('الوزن', '${athlete.weightKg!.toStringAsFixed(1)} كجم'),
          if (athlete.heightCm != null) _infoRow('الطول', '${athlete.heightCm!.toStringAsFixed(0)} سم'),
          if (athlete.sleepBaseline != null) _infoRow('النوم الأساسي', '${athlete.sleepBaseline!.toStringAsFixed(1)} س'),
          if (athlete.restingHRBaseline != null) _infoRow('النبض الأساسي', '${athlete.restingHRBaseline} نبضة/د'),
        ],
      ),
    );
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(label, style: pw.TextStyle(fontSize: 11, color: PdfColors.grey)),
          ),
          pw.Text(value, style: pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  static String _swimLevelLabel(dynamic level) {
    switch (level.toString()) {
      case 'SwimLevel.beginner': return 'مبتدئ';
      case 'SwimLevel.intermediate': return 'متوسط';
      case 'SwimLevel.advanced': return 'متقدم';
      case 'SwimLevel.competitive': return 'تنافسي';
      default: return level.toString();
    }
  }

  static pw.Widget _buildSummarySection(List<DailyLogEntity> logs) {
    final withStress = logs.where((l) => l.stressScore != null).toList();
    final withSleep = logs.where((l) => l.sleepHours != null).toList();
    final withHR = logs.where((l) => l.restingHR != null).toList();
    final withTraining = logs.where((l) => l.training?.trainingLoad != null).toList();
    final withAcwr = logs.where((l) => l.acwr != null).toList();

    final avgStress = withStress.isEmpty ? 0 : withStress.fold<double>(0, (s, l) => s + l.stressScore!) / withStress.length;
    final avgSleep = withSleep.isEmpty ? 0 : withSleep.fold<double>(0, (s, l) => s + l.sleepHours!) / withSleep.length;
    final avgHR = withHR.isEmpty ? 0 : withHR.fold<double>(0, (s, l) => s + l.restingHR!) / withHR.length;
    final avgTrainingLoad = withTraining.isEmpty
        ? 0
        : withTraining.fold<double>(0, (s, l) => s + l.training!.trainingLoad!) / withTraining.length;
    final avgAcwr = withAcwr.isEmpty ? 0 : withAcwr.fold<double>(0, (s, l) => s + l.acwr!) / withAcwr.length;

    return pw.Container(
      padding: pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('ملخص المؤشرات', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _statBox('الإجهاد', avgStress.toStringAsFixed(0)),
              _statBox('النوم', '${avgSleep.toStringAsFixed(1)}س'),
              _statBox('النبض', avgHR.toStringAsFixed(0)),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _statBox('حمل التدريب', avgTrainingLoad.toStringAsFixed(0)),
              _statBox('ACWR', avgAcwr.toStringAsFixed(2)),
              _statBox('الأيام', '${logs.length}'),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _statBox(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _buildBarChart(List<DailyLogEntity> logs) {
    final chartLogs = logs.where((l) => l.stressScore != null).take(14).toList();
    if (chartLogs.isEmpty) {
      return pw.Text('لا توجد بيانات كافية للرسم البياني', style: pw.TextStyle(color: PdfColors.grey));
    }

    final maxStress = chartLogs.fold<int>(0, (s, l) => l.stressScore! > s ? l.stressScore! : s);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('مخطط الإجهاد اليومي', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Container(
          height: 160,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: List.generate(chartLogs.length, (i) {
              final stress = chartLogs[i].stressScore!;
              final barHeight = maxStress > 0 ? (stress / maxStress) * 130.0 : 0.0;
              final dayLabel = chartLogs[i].date.length >= 10 ? chartLogs[i].date.substring(5) : chartLogs[i].date;
              return pw.Expanded(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text('$stress', style: pw.TextStyle(fontSize: 7)),
                    pw.Container(
                      width: 8,
                      height: barHeight,
                      decoration: pw.BoxDecoration(
                        color: _stressColor(stress),
                        borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(2)),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(dayLabel, style: pw.TextStyle(fontSize: 6)),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  static PdfColor _stressColor(int stress) {
    if (stress < 30) return PdfColors.green;
    if (stress < 50) return PdfColors.orange;
    if (stress < 70) return PdfColors.deepOrange;
    return PdfColors.red;
  }

  static pw.Widget _buildLogsTable(List<DailyLogEntity> logs) {
    final displayLogs = logs.take(30).toList();
    if (displayLogs.isEmpty) {
      return pw.Text('لا توجد سجلات', style: pw.TextStyle(color: PdfColors.grey));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('السجلات اليومية', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: pw.FixedColumnWidth(60),
            1: pw.FixedColumnWidth(35),
            2: pw.FixedColumnWidth(35),
            3: pw.FixedColumnWidth(35),
            4: pw.FixedColumnWidth(45),
            5: pw.FixedColumnWidth(45),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.blue50),
              children: [
                _tableCell('التاريخ', isHeader: true),
                _tableCell('النبض', isHeader: true),
                _tableCell('النوم', isHeader: true),
                _tableCell('الإجهاد', isHeader: true),
                _tableCell('حمل التدريب', isHeader: true),
                _tableCell('ACWR', isHeader: true),
              ],
            ),
            ...displayLogs.map((log) => pw.TableRow(
                  children: [
                     _tableCell(log.date.length >= 10 ? log.date.substring(5) : log.date),
                    _tableCell(log.restingHR?.toString() ?? '-'),
                    _tableCell(log.sleepHours != null ? '${log.sleepHours!.toStringAsFixed(1)}س' : '-'),
                    _tableCell(log.stressScore?.toString() ?? '-'),
                    _tableCell(log.training?.trainingLoad?.toString() ?? '-'),
                    _tableCell(log.acwr?.toStringAsFixed(2) ?? '-'),
                  ],
                )),
          ],
        ),
      ],
    );
  }

  static pw.Widget _tableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static Future<void> saveAndOpen(Uint8List pdfBytes) async {
    if (kIsWeb) {
      await Printing.sharePdf(bytes: pdfBytes, filename: 'aquatrack_report.pdf');
      return;
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/aquatrack_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(pdfBytes);
    await Printing.sharePdf(bytes: pdfBytes, filename: file.path.split('\\').last);
  }
}
