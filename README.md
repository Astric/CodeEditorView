# CodeEditorView

A lightweight Swift package for displaying syntax-highlighted code on iOS. Built on CoreText and Tree-sitter, it renders code with a line-number gutter and supports text selection. Currently it doesn't support editing the text.

<img width="315" height="684" alt="Simulator Screenshot" src="https://github.com/user-attachments/assets/850cc0fe-36b2-41b6-b1a5-1978a1898cee" />

## Requirements

- iOS 15+
- Swift 5.9+

Then add `"CodeEditorView"` to your target's dependencies.

## Usage

### SwiftUI

```swift
import SwiftUI
import CodeEditorView

struct ContentView: View {
    let code = "let x = 42"

    var body: some View {
        CodeEditor(code: code, language: try? .swift())
            .wordWrap()
            .theme(.default)
    }
}
```

### UIKit

```swift
import UIKit
import CodeEditorView

let editorView = CodeEditorView()
editorView.text = NSAttributedString(string: "let x = 42")
editorView.wordWrap = true
view.addSubview(editorView)
```

## Supported Languages

| Language | Configuration         |
|----------|-----------------------|
| Swift    | `.swift()`            |
| Python   | `.python()`           |
| JSON     | `.json()`             |
| CSS      | `.css()`              |
| HTML     | `.html()`             |
| Go       | `.golang()`           |

Pass `nil` as the language to display plain text without highlighting.

## Theming

`SyntaxTheme` controls font and token colors. Use the built-in default or create your own:

```swift
let theme = SyntaxTheme(
    baseFont: .monospacedSystemFont(ofSize: 14, weight: .regular),
    baseColor: .label,
    captureColors: [
        "keyword": .systemPink,
        "string":  .systemOrange,
        "comment": .systemGreen,
    ]
)

CodeEditor(code: code, language: try? .python())
    .theme(theme)
```

Common capture names: `keyword`, `string`, `number`, `comment`, `function`, `type`, `variable`, `property`, `operator`, `tag`, `attribute`, `escape`.
