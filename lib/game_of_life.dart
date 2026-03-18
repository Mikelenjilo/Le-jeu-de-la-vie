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
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: GameWidget(game: _game)),

            // Zoom buttons — top right
            Positioned(
              top: 12,
              right: 12,
              child: Column(
                children: [
                  _IconBtn(
                    icon: Icons.zoom_in,
                    color: Colors.purple,
                    tooltip: 'Zoom In',
                    onPressed: _game.zoomIn,
                  ),
                  const SizedBox(height: 8),
                  _IconBtn(
                    icon: Icons.zoom_out,
                    color: Colors.purple,
                    tooltip: 'Zoom Out',
                    onPressed: _game.zoomOut,
                  ),
                ],
              ),
            ),

            // Action buttons — bottom center
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: StatefulBuilder(
                    builder: (context, setInnerState) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _IconBtn(
                          icon: _game.isRunning
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: _game.isRunning ? Colors.red : Colors.teal,
                          tooltip: _game.isRunning ? 'Pause' : 'Play',
                          onPressed: () {
                            _game.toggleRunning();
                            setInnerState(() {});
                          },
                        ),
                        const SizedBox(width: 8),
                        // Speed button with multiplier badge
                        Tooltip(
                          message: 'Speed: ${_game.speedLabel}',
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo.withOpacity(0.9),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(48, 48),
                              padding: EdgeInsets.zero,
                              shape: const CircleBorder(),
                              elevation: 4,
                            ),
                            onPressed: () {
                              _game.cycleSpeed();
                              setInnerState(() {});
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.speed, size: 18),
                                Text(
                                  _game.speedLabel,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _IconBtn(
                          icon: Icons.skip_next,
                          color: Colors.blue,
                          tooltip: 'Next Gen',
                          onPressed: _game.nextGeneration,
                        ),
                        const SizedBox(width: 8),
                        _IconBtn(
                          icon: Icons.shuffle,
                          color: Colors.green,
                          tooltip: 'Randomize',
                          onPressed: _game.randomize,
                        ),
                        const SizedBox(width: 8),
                        _IconBtn(
                          icon: Icons.clear,
                          color: Colors.orange,
                          tooltip: 'Clear',
                          onPressed: _game.clear,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  const _IconBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.9),
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
          elevation: 4,
        ),
        onPressed: onPressed,
        child: Icon(icon),
      ),
    );
  }
}
