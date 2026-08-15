import SwiftUI

public enum CodeTokenKind {
    case comment
    case string
    case number
    case keyword
    case plain
}

/// A minimal, language-agnostic tokenizer that colorizes code blocks.
///
/// The scanner recognizes line and block comments, quoted strings (with escape
/// sequences), numbers (decimal, hex, binary, octal, exponents) and a curated
/// keyword set, emitting an `AttributedString` with per-token colors.
public enum CodeHighlighter {
    private static let keywords: Set<String> = [
        // Swift
        "func", "var", "let", "if", "else", "for", "while", "return",
        "class", "struct", "enum", "import", "guard", "case", "switch",
        "public", "private", "internal", "static", "final", "extension",
        "protocol", "typealias", "in", "do", "catch", "throws", "try",
        "nil", "true", "false", "self", "init", "deinit", "where", "async",
        "await", "actor", "open", "fileprivate", "defer", "break", "continue",
        "default", "fallthrough", "repeat", "super", "lazy", "mutating",
        "override", "required", "convenience", "infix", "postfix", "prefix",
        "operator", "precedencegroup",
        // JavaScript
        "function", "const", "new", "this", "typeof", "of", "with", "as",
        "undefined", "export", "null",
        // Python
        "def", "elif", "except", "finally", "lambda", "pass", "yield",
        "not", "or", "and", "from",
    ]

    public static func color(for kind: CodeTokenKind, palette: Palette) -> Color {
        switch kind {
        case .comment: palette.syntaxComment
        case .string: palette.syntaxString
        case .number: palette.syntaxNumber
        case .keyword: palette.syntaxKeyword
        case .plain: palette.syntaxPlain
        }
    }

    public static func highlight(_ code: String, palette: Palette) -> AttributedString {
        var result = AttributedString()
        var index = code.startIndex
        while index < code.endIndex {
            let (segment, kind) = consumeToken(code, at: &index)
            var attrs = AttributeContainer()
            attrs.foregroundColor = color(for: kind, palette: palette)
            result.append(AttributedString(String(segment), attributes: attrs))
        }
        return result
    }

    // MARK: - Tokenizer

    private static func consumeToken(_ code: String, at index: inout String.Index) -> (Substring, CodeTokenKind) {
        let start = index
        let character = code[index]

        if character.isWhitespace {
            advance(&index, in: code)
            while index < code.endIndex, code[index].isWhitespace {
                advance(&index, in: code)
            }
            return (code[start..<index], .plain)
        }

        if character == "/" {
            if let next = peek(code, after: index) {
                if next == "/" {
                    return (consumeLineComment(code, at: &index), .comment)
                }
                if next == "*" {
                    return (consumeBlockComment(code, at: &index), .comment)
                }
            }
        }

        if character == "\"" || character == "'" || character == "`" {
            return (consumeString(code, at: &index), .string)
        }

        if character.isNumber {
            return (consumeNumber(code, at: &index), .number)
        }

        if character.isLetter || character == "_" {
            let segment = consumeIdentifier(code, at: &index)
            let kind: CodeTokenKind = keywords.contains(String(segment)) ? .keyword : .plain
            return (segment, kind)
        }

        advance(&index, in: code)
        return (code[start..<index], .plain)
    }

    private static func advance(_ index: inout String.Index, in code: String) {
        guard index < code.endIndex else { return }
        index = code.index(after: index)
    }

    private static func peek(_ code: String, after index: String.Index) -> Character? {
        let next = code.index(after: index)
        guard next < code.endIndex else { return nil }
        return code[next]
    }

    private static func consumeLineComment(_ code: String, at index: inout String.Index) -> Substring {
        let start = index
        while index < code.endIndex, code[index] != "\n" {
            advance(&index, in: code)
        }
        return code[start..<index]
    }

    private static func consumeBlockComment(_ code: String, at index: inout String.Index) -> Substring {
        let start = index
        advance(&index, in: code) // consume '/'
        advance(&index, in: code) // consume '*'
        while index < code.endIndex {
            if code[index] == "*" {
                let next = code.index(after: index)
                if next < code.endIndex, code[next] == "/" {
                    advance(&index, in: code)
                    advance(&index, in: code)
                    break
                }
            }
            advance(&index, in: code)
        }
        return code[start..<index]
    }

    private static func consumeString(_ code: String, at index: inout String.Index) -> Substring {
        let start = index
        let quote = code[index]
        advance(&index, in: code) // consume opening quote
        var escaped = false
        while index < code.endIndex {
            let character = code[index]
            if escaped {
                escaped = false
                advance(&index, in: code)
            } else if character == "\\" {
                escaped = true
                advance(&index, in: code)
            } else {
                advance(&index, in: code)
                if character == quote {
                    break
                }
            }
        }
        return code[start..<index]
    }

    private static func consumeNumber(_ code: String, at index: inout String.Index) -> Substring {
        let start = index

        if code[index] == "0", let prefix = peek(code, after: index),
           prefix == "x" || prefix == "b" || prefix == "o" {
            advance(&index, in: code) // consume '0'
            advance(&index, in: code) // consume prefix
            let isHex = prefix == "x"
            while index < code.endIndex {
                let character = code[index]
                if isHex ? character.isHexDigit : character.isNumber, character != "_" {
                    advance(&index, in: code)
                } else if character == "_" {
                    advance(&index, in: code)
                } else {
                    break
                }
            }
            return code[start..<index]
        }

        var sawDot = false
        while index < code.endIndex {
            let character = code[index]
            if character.isNumber || character == "_" {
                advance(&index, in: code)
            } else if character == ".", !sawDot {
                sawDot = true
                advance(&index, in: code)
            } else if character == "e" || character == "E" {
                advance(&index, in: code)
                if index < code.endIndex, code[index] == "+" || code[index] == "-" {
                    advance(&index, in: code)
                }
            } else {
                break
            }
        }
        return code[start..<index]
    }

    private static func consumeIdentifier(_ code: String, at index: inout String.Index) -> Substring {
        let start = index
        while index < code.endIndex {
            let character = code[index]
            if character.isLetter || character.isNumber || character == "_" {
                advance(&index, in: code)
            } else {
                break
            }
        }
        return code[start..<index]
    }
}