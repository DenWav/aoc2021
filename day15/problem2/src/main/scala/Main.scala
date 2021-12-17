package dev.denwav

import scala.collection.mutable
import scala.io.Source
import scala.util.Using
import scala.util.control.Breaks.{break, breakable}

type Grid[T] = Array[Array[T]]

case class Coordinate(x: Int, y: Int) {
  def neighbors: Array[Coordinate] = {
    val res = new Array[Coordinate](4)

    res(0) = Coordinate(x + 1, y)
    res(1) = Coordinate(x - 1, y)
    res(2) = Coordinate(x, y + 1)
    res(3) = Coordinate(x, y - 1)

    res
  }
}

object Coordinate {
  val ZERO: Coordinate = Coordinate(0, 0)
}

object Main {
  def main(args: Array[String]): Unit = {
    val startingGrid: Grid[Int] = Using(Source.fromFile(args(0))) { source =>
      source.getLines.map { s => s.iterator.map { c => c - '0' }.toArray }.toArray
    }.get
    val grid = expandGrid(startingGrid)

    val endCoord = Coordinate(grid(0).length - 1, grid.length - 1)

    val visited: Grid[Boolean] = Array.fill[Boolean](grid.length, grid(0).length)(false)

    val distances: Grid[Int] = Array.fill[Int](grid.length, grid(0).length)(Int.MaxValue)
    distances(Coordinate.ZERO) = 0

    visit(grid, visited, distances, endCoord)

    val selected = findPath(distances, endCoord)
    println(grid.str(selected))

    println()
    println()

    println(distances(endCoord))
  }

  def expandGrid(startingGrid: Grid[Int]): Grid[Int] = {
    val grid = Array.fill[Int](startingGrid.length * 5, startingGrid(0).length * 5)(0)

    val width = startingGrid(0).length
    val height = startingGrid.length

    for (h <- 0 to 4) {
      for (w <- 0 to 4) {
        for (x <- startingGrid(0).indices) {
          for (y <- startingGrid.indices) {
            var newVal = startingGrid(Coordinate(x, y))
            newVal += h + w
            if (newVal > 9) {
              newVal -= 9
            }
            grid(Coordinate(x + (width * w), y + (height * h))) = newVal
          }
        }
      }
    }

    grid
  }

  def visit(grid: Grid[Int], visited: Grid[Boolean], distances: Grid[Int], endCoord: Coordinate): Unit = {
    def order(c: Coordinate): Int = {
      distances(c)
    }

    val queue = new mutable.PriorityQueue[Coordinate]()(Ordering.by(order).reverse)
    queue.enqueue(Coordinate.ZERO)

    while (queue.nonEmpty) {
      val coord = queue.dequeue()
      // Scala has no continue (it has breakable { ... } but it literally accomplishes it by throwing an exception...)
      // So this invert if statement will have to do
      if (!visited(coord)) {
        visited(coord) = true

        val dist = distances(coord)
        coord.neighbors.filter(grid.inBounds).foreach { n =>
          setDistance(grid, visited, distances, n, dist)
          queue.enqueue(n)
        }
      }
    }
  }

  def setDistance(grid: Grid[Int], visited: Grid[Boolean], distances: Grid[Int], coord: Coordinate, minDistance: Int): Unit = {
    if (visited(coord)) {
      return
    }
    val distance = minDistance + grid(coord)
    if (distance < distances(coord)) {
      distances(coord) = distance
    }
  }

  def findPath(distances: Grid[Int], endCoord: Coordinate): Set[Coordinate] = {
    val res = mutable.Set[Coordinate]()

    var prevCoord = endCoord
    var coord = endCoord
    while (coord != Coordinate.ZERO) {
      res.add(coord)
      val c = coord.neighbors.filter(distances.inBounds).filter(c => c != prevCoord).minBy(c => distances(c))
      prevCoord = coord
      coord = c
    }
    res.add(Coordinate.ZERO)

    res.toSet
  }

  extension [T] (grid: Grid[T]) {
    def apply(coordinate: Coordinate): T = grid(coordinate.y)(coordinate.x)
    def update(coordinate: Coordinate, value: T): Unit = grid(coordinate.y)(coordinate.x) = value

    def inBounds(coordinate: Coordinate): Boolean = {
      if (coordinate.x < 0 || coordinate.y < 0) {
        return false
      }
      if (coordinate.x >= grid(0).length || coordinate.y >= grid.length) {
        return false
      }
      true
    }

    def str(highlight: Set[Coordinate] = Set()): String = {
      val sb = mutable.StringBuilder()
      for (y <- grid.indices) {
        for (x <- grid(y).indices) {
          val coord = Coordinate(x, y)
          if (highlight.contains(coord)) {
            sb.append("\u001b[34m") // blue
            sb.append(grid(coord))
            sb.append("\u001b[0m") // reset
          } else {
            sb.append(grid(coord))
          }
        }
        if (y < grid.length - 1) {
          sb.append('\n')
        }
      }
      sb.toString
    }
  }
}
