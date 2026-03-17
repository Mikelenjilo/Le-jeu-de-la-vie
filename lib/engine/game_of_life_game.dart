import 'package:flame/events.dart';
import 'package:flame/game.dart';

import 'infinite_grid.dart';

class GameOfLifeGame extends FlameGame with TapCallbacks, DragCallbacks {
  static const double cellSize = 20.0;
  static const double _minZoom = 0.2;
  static const double _maxZoom = 5.0;
  static const List<double> _speeds = [1.0, 0.5, 0.2, 0.05, 0.01];
  static const List<String> _speedLabels = ['1x', '2x', '5x', '20x', '100x'];

  late InfiniteGrid infiniteGrid;

  int _speedIndex = 0;
  bool _running = false;
  double _elapsed = 0;

  double get _interval => _speeds[_speedIndex];
  String get speedLabel => _speedLabels[_speedIndex];
  bool get isRunning => _running;

  void cycleSpeed() => _speedIndex = (_speedIndex + 1) % _speeds.length;

  void toggleRunning() => _running = !_running;

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
