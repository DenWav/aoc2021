import Foundation

let inputFile = CommandLine.arguments[1]

let text = try String(contentsOfFile: inputFile, encoding: .utf8)
let lines = text.components(separatedBy: "\n")

var template = lines[0]
var rules = [String : Character]()

for line in lines[1...] {
    if line.isEmpty {
        continue
    }
    let parts = line.components(separatedBy: " -> ")
    rules[parts[0]] = parts[1][parts[1].startIndex]
}

for _ in 1...10 {
    var newTemplate = String(template[template.startIndex])
    for i in 0...template.count - 2 {
        let startIndex = template.index(template.startIndex, offsetBy: i)
        let endIndex = template.index(after: startIndex)
        let pair = String(template[startIndex...endIndex])
        let insertion = rules[pair]!
        newTemplate.append(insertion)
        newTemplate.append(template[endIndex])
    }
    template = newTemplate
}

let templateArray: [Character] = Array(template)
let counts = templateArray.reduce(into: [:]) { result, character in
    result[character, default: 0] += 1
}

let max = counts.values.max()!
let min = counts.values.min()!

print(max - min)
