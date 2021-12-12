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

  int counter = 0;
  while (true) {
    grid.step();
    counter++;

    bool allFlashed = true;
    grid.iterateOctopuses((o) {
      allFlashed &= o.flashed;
      return o.flashed;
    });
    if (allFlashed) {
      print(counter);
      break;
    }

    grid.reset();
  }
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

extension Actions on List<List<Octopus>> {
  void step() {
    iterateOctopuses((o) => o.increment());
  }

  void reset() {
    iterateOctopuses((o) => o.reset());
  }

  void iterateOctopuses(final Object? Function(Octopus o) func) {
    for (final row in this) {
      for (final octopus in row) {
        final res = func(octopus);
        if (res is bool && !res) {
          return;
        }
      }
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
