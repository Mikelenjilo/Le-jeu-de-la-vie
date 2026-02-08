import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'dart:math';

// Main game class
class GameOfLifeGame extends FlameGame {
  static const int gridSize = 20;
  static const double cellSize = 20.0;

  late GridWorld gridWorld;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Set camera to show the entire grid
    camera.viewport = FixedResolutionViewport(
      resolution: Vector2(gridSize * cellSize, gridSize * cellSize),
    );

    // Create and add the grid world
    gridWorld = GridWorld(gridSize: gridSize, cellSize: cellSize);
    await add(gridWorld);
  }
}

// Grid World component
class GridWorld extends PositionComponent {
  final int gridSize;
  final double cellSize;
  late List<List<Cell>> cells;

  GridWorld({required this.gridSize, required this.cellSize})
    : super(size: Vector2(gridSize * cellSize, gridSize * cellSize));

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Initialize the grid
    cells = List.generate(
      gridSize,
      (row) => List.generate(
        gridSize,
        (col) => Cell(
          gridPosition: Vector2(col.toDouble(), row.toDouble()),
          cellSize: cellSize,
          isAlive: Random().nextBool(),
        ),
      ),
    );

    // Add all cells to the component tree
    for (var row in cells) {
      for (var cell in row) {
        await add(cell);
      }
    }

    // Add grid lines
    await add(GridLines(gridSize: gridSize, cellSize: cellSize));
  }
}

// Individual cell component
class Cell extends PositionComponent {
  final Vector2 gridPosition;
  final double cellSize;
  bool isAlive;

  Cell({
    required this.gridPosition,
    required this.cellSize,
    required this.isAlive,
  }) : super(
         position: Vector2(
           gridPosition.x * cellSize,
           gridPosition.y * cellSize,
         ),
         size: Vector2(cellSize, cellSize),
       );

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()
      ..color = isAlive ? Colors.black : Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawRect(size.toRect(), paint);
  }

  void setAlive(bool alive) {
    isAlive = alive;
  }
}

// Grid lines component
class GridLines extends Component {
  final int gridSize;
  final double cellSize;

  GridLines({required this.gridSize, required this.cellSize});

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw vertical lines
    for (var i = 0; i <= gridSize; i++) {
      final x = i * cellSize;
      canvas.drawLine(Offset(x, 0), Offset(x, gridSize * cellSize), paint);
    }

    // Draw horizontal lines
    for (var i = 0; i <= gridSize; i++) {
      final y = i * cellSize;
      canvas.drawLine(Offset(0, y), Offset(gridSize * cellSize, y), paint);
    }
  }
}

// Main widget to run the game
class GameOfLifeWidget extends StatefulWidget {
  const GameOfLifeWidget({Key? key}) : super(key: key);

  @override
  State<GameOfLifeWidget> createState() => _GameOfLifeWidgetState();
}

class _GameOfLifeWidgetState extends State<GameOfLifeWidget> {
  late GameOfLifeGame game;

  @override
  void initState() {
    super.initState();
    game = GameOfLifeGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game of Life - 20x20 Grid')),
      body: Center(child: GameWidget(game: game)),
    );
  }
}
