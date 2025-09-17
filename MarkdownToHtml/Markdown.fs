module Markdown

type MarkdownElement =
    | Paragraph of string
    | Heading of int * string
    | Bold of string
    | Italic of string
    | Strikethrough of string