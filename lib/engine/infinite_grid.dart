import 'dart:collection';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../models/cell_model.dart';
import 'game_of_life_game.dart';

class InfiniteGrid extends Component {
  final GameOfLifeGame game;
  final double cellSize;

  final HashSet<Cell> _alive = HashSet();
  final Random _rng = Random();

  static final _alivePaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.fill;
  static final _bgPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;
  static final _gridPaint = Paint()
    ..color = Colors.grey.withValues(alpha: 0.3)
    ..strokeWidth = 0.5
    ..style = PaintingStyle.stroke;

  InfiniteGrid({required this.game, required this.cellSize});

  void toggleCell(int row, int col) {
    final pos = Cell(row, col);
    if (!_alive.remove(pos)) _alive.add(pos);
  }

  void randomize() {
    _alive.clear();
    for (int r = -20; r < 20; r++) {
      for (int c = -20; c < 20; c++) {
        if (_rng.nextBool()) _alive.add(Cell(r, c));
      }
    }
  }

  void clear() => _alive.clear();

  void nextGeneration() {
    // Accumulate neighbor counts for every cell adjacent to a live cell
    final neighborCount = HashMap<Cell, int>();
    for (final cell in _alive) {
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          if (dr == 0 && dc == 0) continue;
          final n = Cell(cell.row + dr, cell.col + dc);
          neighborCount[n] = (neighborCount[n] ?? 0) + 1;
        }
      }
    }

    // Apply rules to every candidate cell
    final next = HashSet<Cell>();
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

    final left = cam.x - half.x / zoom;
    final top = cam.y - half.y / zoom;
    final right = cam.x + half.x / zoom;
    final bottom = cam.y + half.y / zoom;

    final minCol = (left / cellSize).floor() - 1;
    final maxCol = (right / cellSize).ceil() + 1;
    final minRow = (top / cellSize).floor() - 1;
    final maxRow = (bottom / cellSize).ceil() + 1;

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
