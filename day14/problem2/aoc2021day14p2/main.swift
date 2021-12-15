import Foundation

let inputFile = CommandLine.arguments[1]

let text = try String(contentsOfFile: inputFile, encoding: .utf8)
let lines = text.components(separatedBy: "\n")

let template = lines[0]

let rules: [String : Character] = lines[1...].reduce(into: [:]) { result, line in
    if line.isEmpty {
        return
    }
    let parts = line.components(separatedBy: " -> ")
    result[parts[0]] = parts[1][parts[1].startIndex]
}

// Mapping goes pair -> depth -> character -> score
var countMap = [String : [Int : [Character : Int64]]]()

func walk(pair: String, depth: Int) -> [Character : Int64] {
    let score = countMap[pair]?[depth]
    if score != nil {
        return score!
    }

    let start = pair.first!
    let end = pair.last!

    if (depth == 40) {
        var res = [Character : Int64]()
        if start == end {
            res[start] = 2
        } else {
            res[start] = 1
            res[end] = 1
        }
        return res
    }

    let insertion = rules[pair]!
    let leftPair = String([start, insertion])
    let leftScore = walk(pair: leftPair, depth: depth + 1)

    let rightPair = String([insertion, end])
    let rightScore = walk(pair: rightPair, depth: depth + 1)

    var computedScore = leftScore.merging(rightScore) { left, right in left + right }
    computedScore[insertion, default: 0] -= 1 // Don't double count

    var pairMap = countMap[pair, default: [Int : [Character : Int64]]()]
    pairMap[depth] = computedScore
    // Default value isn't automatically stored in the dictionary
    countMap[pair] = pairMap

    return computedScore
}

var score = [Character : Int64]()
for i in 0...template.count - 2 {
    let startIndex = template.index(template.startIndex, offsetBy: i)
    let endIndex = template.index(after: startIndex)
    let pair = String(template[startIndex...endIndex])

    var pairScore = walk(pair: pair, depth: 0)
    pairScore[template[startIndex], default: 0] -= 1 // don't double count
    score = score.merging(pairScore) { left, right in left + right }
}
score[template[template.startIndex], default: 0] += 1 // we skipped the first char in counting

let max = score.values.max()!
let min = score.values.min()!

print(max - min)
