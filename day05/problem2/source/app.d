import std.algorithm;
import std.ascii;
import std.conv;
import std.math;
import std.stdio;
import std.string;

struct PointPair {
    Point left;
    Point right;
}

struct Point {
    int x;
    int y;
}

Point parseCoords(const string coords) @safe pure {
    string[] parts = coords.split(",");
    const Point result = { x: parse!int(parts[0]), y: parse!int(parts[1]) };
    return result;
}

PointPair parseLine(const string line) @safe pure {
    auto parts = line.split(" -> ");
    const PointPair result = { left: parseCoords(parts[0]), right: parseCoords(parts[1]) };
    return result;
}

bool isHorizontalOrVert(const PointPair *pair) {
    return pair.left.x == pair.right.x || pair.left.y == pair.right.y;
}

void countPointsBetweenHorizontalOrVert(const PointPair *pair, int[Point] *pointCounts) @safe {
    const int minX = min(pair.left.x, pair.right.x);
    const int maxX = max(pair.left.x, pair.right.x);
    const int minY = min(pair.left.y, pair.right.y);
    const int maxY = max(pair.left.y, pair.right.y);

    for (int i = minX; i <= maxX; i++) {
        for (int j = minY; j <= maxY; j++) {
            const Point thisPoint = { x: i, y: j };
            int *count = thisPoint in *pointCounts;
            if (count !is null) {
                *count += 1;
            } else {
                (*pointCounts)[thisPoint] = 1;
            }
        }
    }
}

void countPointsBetweenDiag(const PointPair *pair, int[Point] *pointCounts) @safe {
    const int xDir = -sgn(pair.left.x - pair.right.x);
    const int yDir = -sgn(pair.left.y - pair.right.y);

    int i = pair.left.x;
    int j = pair.left.y;

    while (i != pair.right.x + xDir && j != pair.right.y + yDir) {
        const Point thisPoint = { x: i, y: j };
        int *count = thisPoint in *pointCounts;
        if (count !is null) {
            *count += 1;
        } else {
            (*pointCounts)[thisPoint] = 1;
        }

        i += xDir;
        j += yDir;
    }
}

void main() {
    auto inputFile = File("input.txt", "r");
    int[Point] pointCounts;

    foreach (line ; inputFile.byLine) {
        const auto pair = parseLine(to!string(line));
        if (isHorizontalOrVert(&pair)) {
            countPointsBetweenHorizontalOrVert(&pair, &pointCounts);
        } else {
            countPointsBetweenDiag(&pair, &pointCounts);
        }
    }
    inputFile.close();

    int count = 0;
    foreach (i ; pointCounts.byValue) {
        if (i > 1) {
            count++;
        }
    }

    writeln(count);
}
