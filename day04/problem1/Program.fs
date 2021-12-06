open System
open System.IO
open System.Text.RegularExpressions

type BingoValue =
    class
        val value : int
        val mutable selected : bool

        new (value, selected) = { value = value; selected = selected }

        member this.playValue(num : int): unit =
            if this.value = num then this.selected <- true

        static member isSelected(v : BingoValue): bool = v.selected

        override this.ToString(): string =
            (
                if this.selected then $"[%d{this.value}]"
                else string this.value
            ).PadLeft 4
    end

type BingoRow =
    class
        val elements : BingoValue[]

        new (elements) = { elements = elements }

        member this.playValue(num : int): unit =
            for v in this.elements do
                v.playValue num

        override this.ToString(): string =
            this.elements |> Seq.map (fun v -> v.ToString()) |> String.concat " "
    end

type BingoBoard =
    class
        val rows : BingoRow[]

        new (rows) = { rows = rows }

        member this.playValue(num : int): unit =
            for r in this.rows do
                r.playValue num

        member this.isWinner(): bool =
            if this.isRowWinner() then true
            elif this.isColWinner() then true
            else false

        member private this.isRowWinner(): bool =
            let doesRowWin = (fun (r : BingoRow) -> r.elements |> Seq.forall BingoValue.isSelected)
            this.rows |> Seq.exists doesRowWin

        member private this.isColWinner(): bool =
            let doesColWin = (fun (i : int) -> this.rows |> Seq.forall (fun (r : BingoRow) -> r.elements[i].selected))
            let indexSeq = seq { 0 .. this.rows.Length - 1 }
            indexSeq |> Seq.exists doesColWin

        member this.calculateScore (i : int) : int =
            (
                this.rows |> Seq.sumBy (
                    fun r ->
                        r.elements
                            |> Seq.filter (fun v -> not v.selected)
                            |> Seq.sumBy (fun v -> v.value)
                )
            ) * i

        override this.ToString(): string =
            this.rows |> Seq.map (fun r -> r.ToString()) |> String.concat "\n"
    end

let boardRowToTuple (row : int[]) : BingoRow =
    let valueRow = row |> Array.map (fun i -> BingoValue(i, false))
    if valueRow.Length <> 5 then raise (Exception($"Row is the wrong length: %d{valueRow.Length}"))
    else BingoRow(valueRow)

let convertChunkToBoard (boards : int[][]) : BingoBoard =
    let rows = boards |> Seq.map boardRowToTuple |> Seq.toArray
    if rows.Length <> 5 then raise (Exception($"Chunk is the wrong length: %d{rows.Length}"))
    else BingoBoard(rows)

let parseBoards (boards : int[][]) : BingoBoard[] =
    boards |> Seq.chunkBySize 5 |> Seq.map convertChunkToBoard |> Seq.toArray

let readAllLines (reader : TextReader) : int[][] =
    // simple function which ignores the param
    let read _ = reader.ReadLine()
    let isNotNull = function null -> false | _ -> true
    let toInts (line : String) = Regex.Split(line.Trim(), "\\s+") |> Seq.map int |> Seq.toArray

    Seq.initInfinite read
        |> Seq.takeWhile isNotNull
        |> Seq.filter (fun s -> not <| String.IsNullOrWhiteSpace(s))
        |> Seq.map toInts
        |> Seq.toArray

[<EntryPoint>]
let main argv =
    let reader =
        if argv.Length = 1 then new StreamReader (argv[0])
        else new StreamReader (Console.OpenStandardInput())

    let numbers = reader.ReadLine().Split [|','|] |> Array.map int

    let boards = readAllLines reader
    let boards = parseBoards boards

    let winningScore = numbers |> Seq.tryPick (
        fun num ->
            let winner = boards |> Seq.tryFind (
                fun b ->
                    b.playValue(num)
                    b.isWinner()
            )
            if winner.IsNone then option.None
            else option.Some(winner.Value.calculateScore(num))
    )

    match winningScore with
    | Some score -> printfn $"%d{score}"
    | None -> printfn "No winning board found"

    0

