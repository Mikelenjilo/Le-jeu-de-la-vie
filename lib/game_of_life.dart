import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'engine/game_of_life_game.dart';

class GameOfLifeWidget extends StatefulWidget {
  const GameOfLifeWidget({super.key});
  @override
  State<GameOfLifeWidget> createState() => _GameOfLifeWidgetState();
}

class _GameOfLifeWidgetState extends State<GameOfLifeWidget> {
  late GameOfLifeGame _game;

  @override
  void initState() {
    super.initState();
    _game = GameOfLifeGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conway\'s Game of Life ∞')),
      body: Column(
        children: [
          Expanded(child: GameWidget(game: _game)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                StatefulBuilder(
                  builder: (context, setInnerState) => _Btn(
                    icon: _game.isRunning ? Icons.pause : Icons.play_arrow,
                    label: _game.isRunning ? 'Pause' : 'Play',
                    color: _game.isRunning ? Colors.red : Colors.teal,
                    onPressed: () {
                      _game.toggleRunning();
                      setInnerState(() {}); // rebuild just this button
                    },
                  ),
                ),
                StatefulBuilder(
                  builder: (context, setInnerState) => _Btn(
                    icon: Icons.speed,
                    label: _game.speedLabel,
                    color: Colors.indigo,
                    onPressed: () {
                      _game.cycleSpeed();
                      setInnerState(() {});
                    },
                  ),
                ),

                _Btn(
                  icon: Icons.skip_next,
                  label: 'Next Gen',
                  color: Colors.blue,
                  onPressed: _game.nextGeneration,
                ),
                _Btn(
                  icon: Icons.shuffle,
                  label: 'Randomize',
                  color: Colors.green,
                  onPressed: _game.randomize,
                ),
                _Btn(
                  icon: Icons.clear,
                  label: 'Clear',
                  color: Colors.orange,
                  onPressed: _game.clear,
                ),
                _Btn(
                  icon: Icons.zoom_in,
                  label: 'Zoom In',
                  color: Colors.purple,
                  onPressed: _game.zoomIn,
                ),
                _Btn(
                  icon: Icons.zoom_out,
                  label: 'Zoom Out',
                  color: Colors.purple,
                  onPressed: _game.zoomOut,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  const _Btn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      icon: Icon(icon),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}
