import 'dart:collection';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

// ─── Cell coordinate with value equality ─────────────────────────────────────

class CellPos {
  final int row, col;
  const CellPos(this.row, this.col);
  @override
  bool operator ==(Object o) => o is CellPos && o.row == row && o.col == col;
  @override
  int get hashCode => Object.hash(row, col);
}

// ─── Game ─────────────────────────────────────────────────────────────────────

class GameOfLifeGame extends FlameGame with TapCallbacks, DragCallbacks {
  static const double cellSize = 20.0;
  static const double _minZoom = 0.2;
  static const double _maxZoom = 5.0;

  double get _interval => _speeds[_speedIndex];

  static const List<double> _speeds = [1.0, 0.5, 0.2, 0.05, 0.01];
  static const List<String> _speedLabels = ['1x', '2x', '5x', '20x', '100x'];
  int _speedIndex = 0;

  void cycleSpeed() => _speedIndex = (_speedIndex + 1) % _speeds.length;
  String get speedLabel => _speedLabels[_speedIndex];

  bool _running = false;
  double _elapsed = 0;

  late InfiniteGrid infiniteGrid;

  void toggleRunning() => _running = !_running;
  bool get isRunning => _running;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    infiniteGrid = InfiniteGrid(game: this, cellSize: cellSize);
    await world.add(infiniteGrid);
    infiniteGrid.randomize();
  }

  @override // ← add here, after onLoad
  void update(double dt) {
    super.update(dt);
    if (!_running) return;
    _elapsed += dt;
    if (_elapsed >= _interval) {
      _elapsed = 0;
      infiniteGrid.nextGeneration();
    }
  }

  // Use onTapUp so accidental drag-starts don't toggle cells
  @override
  void onTapUp(TapUpEvent event) {
    final wp = _screenToWorld(event.localPosition);
    infiniteGrid.toggleCell(
      (wp.y / cellSize).floor(),
      (wp.x / cellSize).floor(),
    );
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    // Move camera opposite to drag direction so the world "follows" the finger
    camera.viewfinder.position -= event.localDelta;
  }

  Vector2 _screenToWorld(Vector2 screenPos) {
    final zoom = camera.viewfinder.zoom;
    return camera.viewfinder.position + (screenPos - size / 2) / zoom;
  }

  void nextGeneration() => infiniteGrid.nextGeneration();
  void randomize() => infiniteGrid.randomize();
  void clear() => infiniteGrid.clear();

  void zoomIn() => _setZoom(camera.viewfinder.zoom * 1.3);
  void zoomOut() => _setZoom(camera.viewfinder.zoom / 1.3);

  void _setZoom(double z) {
    camera.viewfinder.zoom = z.clamp(_minZoom, _maxZoom);
  }
}

// ─── Infinite Grid ────────────────────────────────────────────────────────────

class InfiniteGrid extends Component {
  final GameOfLifeGame game;
  final double cellSize;

  final HashSet<CellPos> _alive = HashSet();
  final Random _rng = Random();

  static final _alivePaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.fill;
  static final _bgPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;
  static final _gridPaint = Paint()
    ..color = Colors.grey.withOpacity(0.3)
    ..strokeWidth = 0.5
    ..style = PaintingStyle.stroke;

  InfiniteGrid({required this.game, required this.cellSize});

  void toggleCell(int row, int col) {
    final pos = CellPos(row, col);
    if (!_alive.remove(pos)) _alive.add(pos);
  }

  void randomize() {
    _alive.clear();
    for (int r = -20; r < 20; r++) {
      for (int c = -20; c < 20; c++) {
        if (_rng.nextBool()) _alive.add(CellPos(r, c));
      }
    }
  }

  void clear() => _alive.clear();

  // Conway's rules — runs entirely on the HashSet, no grid size limit
  void nextGeneration() {
    // Accumulate neighbor counts for every cell adjacent to a live cell
    final neighborCount = HashMap<CellPos, int>();
    for (final cell in _alive) {
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          if (dr == 0 && dc == 0) continue;
          final n = CellPos(cell.row + dr, cell.col + dc);
          neighborCount[n] = (neighborCount[n] ?? 0) + 1;
        }
      }
    }

    // Apply rules to every candidate cell
    final next = HashSet<CellPos>();
    for (final entry in neighborCount.entries) {
      final n = entry.value;
      final wasAlive = _alive.contains(entry.key);
      if (wasAlive && (n == 2 || n == 3)) next.add(entry.key);
      if (!wasAlive && n == 3) next.add(entry.key);
    }

    _alive
      ..clear()
      ..addAll(next);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final cam = game.camera.viewfinder.position;
    final zoom = game.camera.viewfinder.zoom;
    final half = game.size / 2;

    // ✅ Divide by zoom so the visible world region grows when zooming out
    final left = cam.x - half.x / zoom;
    final top = cam.y - half.y / zoom;
    final right = cam.x + half.x / zoom;
    final bottom = cam.y + half.y / zoom;

    final minCol = (left / cellSize).floor() - 1;
    final maxCol = (right / cellSize).ceil() + 1;
    final minRow = (top / cellSize).floor() - 1;
    final maxRow = (bottom / cellSize).ceil() + 1;

    // White background for the visible region
    canvas.drawRect(
      Rect.fromLTRB(
        minCol * cellSize,
        minRow * cellSize,
        maxCol * cellSize,
        maxRow * cellSize,
      ),
      _bgPaint,
    );

    // Alive cells (only those in view)
    for (final cell in _alive) {
      if (cell.col >= minCol &&
          cell.col <= maxCol &&
          cell.row >= minRow &&
          cell.row <= maxRow) {
        canvas.drawRect(
          Rect.fromLTWH(
            cell.col * cellSize,
            cell.row * cellSize,
            cellSize,
            cellSize,
          ),
          _alivePaint,
        );
      }
    }

    // Grid lines
    for (int c = minCol; c <= maxCol; c++) {
      final x = c * cellSize;
      canvas.drawLine(
        Offset(x, minRow * cellSize),
        Offset(x, maxRow * cellSize),
        _gridPaint,
      );
    }
    for (int r = minRow; r <= maxRow; r++) {
      final y = r * cellSize;
      canvas.drawLine(
        Offset(minCol * cellSize, y),
        Offset(maxCol * cellSize, y),
        _gridPaint,
      );
    }
  }
}

// ─── Widget ───────────────────────────────────────────────────────────────────

class GameOfLifeWidget extends StatefulWidget {
  const GameOfLifeWidget({Key? key}) : super(key: key);
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
