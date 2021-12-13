setClass("Node", slots = list(name = "character", isBig = "logical"))

# Have to do horrible hacks because pass-by-reference is impossible with R...
findOrCreateNode <- function(nodes, name) {
  if (name %in% names(nodes)) {
    nodes[[name]]
  } else {
    node <- new("Node", name = name, isBig = name == toupper(name))
    eval.parent(substitute(nodes[[name]] <- node))
    node
  }
}

findOrCreateConnection <- function(connections, name) {
  if (name %in% names(connections)) {
    connections[[name]]
  } else {
    connection <- list()
    eval.parent(substitute(connections[[name]] <- connections))
    connection
  }
}

nodes <- list()
connections <- list()

lines <- readLines("./input.txt")
for (line in lines) {
  parts <- strsplit(line, '-')
  from <- parts[[1]][1]
  to <- parts[[1]][2]

  fromNode <- findOrCreateNode(nodes, from)
  toNode <- findOrCreateNode(nodes, to)

  fromConnections <- findOrCreateConnection(connections, from)
  toConnections <- findOrCreateConnection(connections, to)

  connections[[from]] <- append(fromConnections, to)
  connections[[to]] <- append(toConnections, from)
}

walk <- function(nodes, connections, node, seen) {
  # Reached the end
  if (node@name == "end") {
    return(1)
  }

  # Already visited
  if (node@name %in% seen) {
    return(-1)
  }
  # Only record visited names for small caves
  if (!node@isBig) {
    seen <- append(seen, node@name)
  }

  count <- 0

  canMove <- FALSE

  con <- connections[[node@name]]
  for (c in con) {
    newNode <- nodes[[c]]
    newCount <- walk(nodes, connections, newNode, seen)
    if (newCount == -1) {
      next
    }

    canMove <- TRUE
    count <- count + newCount
  }

  if (!canMove) {
    return(-1)
  } else {
    return(count)
  }
}

count <- walk(nodes, connections, nodes[["start"]], list())
print(count)
