import 'package:flutter/material.dart';
import '../../domain/entities/pain_report.dart';

class PainMappingDialog extends StatefulWidget {
  final String muscleId;
  final String muscleName;

  const PainMappingDialog({
    super.key,
    required this.muscleId,
    required this.muscleName,
  });

  @override
  State<PainMappingDialog> createState() => _PainMappingDialogState();
}

class _PainMappingDialogState extends State<PainMappingDialog> {
  PainSeverity _severity = PainSeverity.low;
  PainType _type = PainType.aching;
  bool _duringSwimming = false;
  bool _afterSwimming = false;
  bool _duringFitness = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Report Pain: ${widget.muscleName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Severity (1-10):', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<PainSeverity>(
              value: _severity,
              isExpanded: true,
              items: PainSeverity.values.map((s) {
                return DropdownMenuItem(
                  value: s,
                  child: Text(s.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _severity = val);
              },
            ),
            const SizedBox(height: 16),
            const Text('Pain Type:', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<PainType>(
              value: _type,
              isExpanded: true,
              items: PainType.values.map((t) {
                return DropdownMenuItem(
                  value: t,
                  child: Text(t.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _type = val);
              },
            ),
            const SizedBox(height: 16),
            const Text('When does it happen?', style: TextStyle(fontWeight: FontWeight.bold)),
            CheckboxListTile(
              title: const Text('During Swimming'),
              value: _duringSwimming,
              onChanged: (v) => setState(() => _duringSwimming = v ?? false),
            ),
            CheckboxListTile(
              title: const Text('After Swimming'),
              value: _afterSwimming,
              onChanged: (v) => setState(() => _afterSwimming = v ?? false),
            ),
            CheckboxListTile(
              title: const Text('During Fitness Training'),
              value: _duringFitness,
              onChanged: (v) => setState(() => _duringFitness = v ?? false),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final report = PainReport(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              athleteId: 'current_user', // To be injected
              muscleId: widget.muscleId,
              date: DateTime.now(),
              severity: _severity,
              type: _type,
              duringSwimming: _duringSwimming,
              afterSwimming: _afterSwimming,
              duringFitness: _duringFitness,
            );
            Navigator.pop(context, report);
          },
          child: const Text('Save Report'),
        ),
      ],
    );
  }
}
