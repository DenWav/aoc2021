import 'dart:convert';
import 'dart:io';

void main() async {
  final grid = await File("input.txt")
      .openRead()
      .map(ascii.decode)
      .transform(LineSplitter())
      .map((line) {
        return line.runes
            .map((i) => i - '0'.codeUnitAt(0))
            .map(Octopus.new)
            .toList(growable: false);
      }).toList();

  configureNeighbors(grid);

  for (int i = 0; i < 100; i++) {
    step(grid);
    reset(grid);
  }

  int sum = 0;
  iterateOctopuses(grid, (o) => sum += o.flashes);
  print(sum);
}

void configureNeighbors(final List<List<Octopus>> grid) {
  for (int i = 0; i < grid.length; i++) {
    final row = grid[i];

    for (int j = 0; j < grid[i].length; j++) {
      final Octopus o = row[j];

      for (int k = 0; k < 3; k++) {
        for (int l = 0; l < 3; l++) {
          final rowIndex = i - 1 + k;
          final colIndex = j - 1 + l;

          if (rowIndex == i && colIndex == j) {
            continue;
          }
          if (rowIndex < 0 || colIndex < 0 || rowIndex >= grid.length || colIndex >= grid[rowIndex].length) {
            continue;
          }

          grid[rowIndex][colIndex].neighbors.add(o);
        }
      }
    }
  }
}

void step(final List<List<Octopus>> grid) {
  iterateOctopuses(grid, (o) => o.increment());
}

void reset(final List<List<Octopus>> grid) {
  iterateOctopuses(grid, (o) => o.reset());
}

void iterateOctopuses(final List<List<Octopus>> grid, final void Function(Octopus o) func) {
  for (final row in grid) {
    for (final octopus in row) {
      func(octopus);
    }
  }
}

class Octopus {
  int _value;
  int flashes = 0;
  bool flashed = false;

  final List<Octopus> neighbors = [];

  Octopus(this._value);

  void increment() {
    if (this.flashed) {
      return;
    }

    this._value++;

    if (this._value == 10) {
      this.flashes++;
      this.flashed = true;
      this._value = 0;

      for (final neighbor in this.neighbors) {
        neighbor.increment();
      }
    }
  }

  void reset() {
    this.flashed = false;
  }

  @override
  String toString() {
    return "🐙|${this._value}|";
  }
}
