import 'package:flutter/material.dart';
import '../../domain/usecases/knowledge_graph_engine.dart';
import '../../domain/entities/muscle.dart';

class InteractiveAnatomyMap extends StatefulWidget {
  final String activeSwimStroke;
  final Function(String muscleName)? onMuscleTapped;

  const InteractiveAnatomyMap({
    super.key,
    required this.activeSwimStroke,
    this.onMuscleTapped,
  });

  @override
  State<InteractiveAnatomyMap> createState() => _InteractiveAnatomyMapState();
}

class _InteractiveAnatomyMapState extends State<InteractiveAnatomyMap> {
  final KnowledgeGraphEngine _graphEngine = KnowledgeGraphEngine();
  late Map<String, ActivationLevel> _activationMap;

  @override
  void initState() {
    super.initState();
    _updateActivationMap();
  }

  @override
  void didUpdateWidget(covariant InteractiveAnatomyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeSwimStroke != widget.activeSwimStroke) {
      _updateActivationMap();
    }
  }

  void _updateActivationMap() {
    setState(() {
      _activationMap = _graphEngine.getMuscleActivationMap(widget.activeSwimStroke);
    });
  }

  Color _getColorForActivation(ActivationLevel level) {
    switch (level) {
      case ActivationLevel.veryHigh:
        return Colors.red;
      case ActivationLevel.high:
        return Colors.orange;
      case ActivationLevel.medium:
        return Colors.yellow;
      case ActivationLevel.low:
        return Colors.blue;
      case ActivationLevel.none:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Note: In production, this will use an InteractiveViewer and a layered SVG package 
    // or a custom painter reading vector paths to allow tapping distinct muscles.
    // This is the architectural scaffold for it.
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Muscle Activation: ${widget.activeSwimStroke}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: InteractiveViewer(
            maxScale: 5.0,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Base Body Layer Placeholder
                Container(
                  width: 300,
                  height: 600,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text('Base Body SVG Placeholder', style: TextStyle(color: Colors.white54)),
                  ),
                ),
                
                // Overlay Muscles
                ..._activationMap.entries.map((entry) {
                  return Positioned(
                    top: _getDummyTopPosition(entry.key),
                    child: GestureDetector(
                      onTap: () {
                        if (widget.onMuscleTapped != null) {
                          widget.onMuscleTapped!(entry.key);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getColorForActivation(entry.value).withAlpha(204),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          entry.key,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Dummy positions for placeholder UI
  double _getDummyTopPosition(String muscle) {
    switch (muscle) {
      case 'Deltoids':
        return 100;
      case 'Latissimus Dorsi':
        return 200;
      case 'Core':
        return 300;
      case 'Glutes':
        return 400;
      default:
        return 500;
    }
  }
}
