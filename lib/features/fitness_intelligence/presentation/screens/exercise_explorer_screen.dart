import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../domain/entities/exercise.dart';

class ExerciseExplorerScreen extends StatelessWidget {
  final Exercise exercise;

  const ExerciseExplorerScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(exercise.name),
        backgroundColor: Colors.blueAccent.shade700,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Exercise Animation Area (using Lottie for extremely lightweight vector animations instead of heavy MP4s)
            Container(
              height: 250,
              color: Colors.black12,
              child: exercise.lottieUrl != null
                  ? Lottie.network(
                      exercise.lottieUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Text('Animation not available'),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.ondemand_video, size: 64, color: Colors.grey),
                    ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Training Goal: ${exercise.trainingGoal}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.blueAccent.shade700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(label: Text(exercise.difficulty.name.toUpperCase())),
                      Chip(label: Text('Age: ${exercise.recommendedAge}')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(exercise.description),
                  const Divider(height: 32),
                  
                  ListTile(
                    leading: const Icon(Icons.fitness_center),
                    title: const Text('Sets & Reps'),
                    subtitle: Text(exercise.setsAndReps),
                  ),
                  ListTile(
                    leading: const Icon(Icons.timer),
                    title: const Text('Rest Period'),
                    subtitle: Text(exercise.restPeriod),
                  ),
                  
                  const Divider(height: 32),
                  const Text('Common Mistakes ⚠️', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange)),
                  ...exercise.commonMistakes.map((m) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Colors.orange, fontSize: 18)),
                        Expanded(child: Text(m)),
                      ],
                    ),
                  )),
                  
                  const SizedBox(height: 16),
                  const Text('Safety Instructions 🛡️', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
                  ...exercise.safetyInstructions.map((s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Colors.red, fontSize: 18)),
                        Expanded(child: Text(s)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
