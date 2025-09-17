// For more information see https://aka.ms/fsharp-console-apps
open System
open Markdown
open System.Numerics

let capitalizeFirstLetter (input: string) =
    match input with
    | null -> "" // Handle null input by returning an empty string
    | "" -> "" // If the string is empty, return an empty string
    | s when s.Length = 1 -> s.ToUpper() // If it's a single character, just uppercase it
    | s ->
        // For strings with more than one character:
        // Take the first character, convert it to uppercase.
        // Take the rest of the string (from index 1), convert it to lowercase.
        // Concatenate them.
        (string s[0]).ToUpper() + (s.Substring(1)).ToLower()


let hello s : string =
    match s with
    | null -> "Hello, World!"
    | _ -> s |> capitalizeFirstLetter |> sprintf "Hello, %s!"


let parseLine (line: string) : MarkdownElement option =
    if line.StartsWith("# ") then
        Some(Heading(1, line.Substring(2).Trim()))
    elif line.StartsWith("## ") then
        Some(Heading(2, line.Substring(3).Trim()))
    elif line.StartsWith("### ") then
        Some(Heading(3, line.Substring(4).Trim()))
    elif String.IsNullOrWhiteSpace line then
        None
    else
        Some(Paragraph line)

let parseMarkdown (lines: string list) : MarkdownElement list = lines |> List.choose parseLine

let parseInline (text: string) : string =
    text
    |> fun s -> System.Text.RegularExpressions.Regex.Replace(s, @"\*\*(.*?)\*\*", "<b>$1</b>")
    |> fun s -> System.Text.RegularExpressions.Regex.Replace(s, @"_(.*?)_", "<i>$1</i>")
    |> fun s -> System.Text.RegularExpressions.Regex.Replace(s, @"~~(.*?)~~", "<s>$1</s>")

let renderHtml (element: MarkdownElement) : string =
    match element with
    | Heading(level, text) -> sprintf "<h%d>%s</h%d>" level (parseInline text) level
    | Paragraph text -> sprintf "<p>%s</p>" (parseInline text)
    | _ -> ""

[<EntryPoint>]
let main argv =
    let input =
        [ "# Heading 1"
          "## Heading 2"
          "### Heading 3"
          "This **is** a ~~sentence~~ paragraph."
          "" ]

    let ast = parseMarkdown input
    let html = ast |> List.map renderHtml |> String.concat "\n"
    printfn "%s" html
    0 // return an integer exit code
