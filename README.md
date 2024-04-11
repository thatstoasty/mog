Mog
=========

Style definitions for nice terminal layouts. Built with TUIs in mind.

![Lip Gloss example](https:#stuff.charm.sh/lipgloss/lipgloss-example.png)

Lip Gloss takes an expressive, declarative approach to terminal rendering.
Users familiar with CSS will feel at home with Lip Gloss.

```mojo

import "github.com/charmbracelet/lipgloss"

var style = Style.new().
    bold(True).
    foreground("#FAFAFA")).
    background("#7D56F4")).
    padding_top(2).
    padding_left(4).
    width(22)

print(style.render("Hello, kitty"))
```

## Colors

Lip Gloss supports the following color profiles:

### ANSI 16 colors (4-bit)

```mojo
"5")  # magenta
"9")  # red
"12") # light blue
```

### ANSI 256 Colors (8-bit)

```mojo
"86")  # aqua
"201") # hot pink
"202") # orange
```

### True Color (16,777,216 colors; 24-bit)

```mojo
"#0000FF") # good ol' 100% blue
"#04B575") # a green
"#3C3C3C") # a dark gray
```

...as well as a 1-bit ASCII profile, which is black and white only.

The terminal's color profile will be automatically detected, and colors outside
the gamut of the current palette will be automatically coerced to their closest
available value.

### Adaptive Colors

You can also specify color options for light and dark backgrounds:

```mojo
lipgloss.AdaptiveColor{Light: "236", Dark: "248"}
```

The terminal's background color will automatically be detected and the
appropriate color will be chosen at runtime.

### Complete Colors

CompleteColor specifies exact values for truecolor, ANSI256, and ANSI color
profiles.

```mojo
lipgloss.CompleteColor{True: "#0000FF", ANSI256: "86", ANSI: "5"}
```

Automatic color degradation will not be performed in this case and it will be
based on the color specified.

### Complete Adaptive Colors

You can use CompleteColor with AdaptiveColor to specify the exact values for
light and dark backgrounds without automatic color degradation.

```mojo
lipgloss.CompleteAdaptiveColor{
    Light: CompleteColor{TrueColor: "#d7ffae", ANSI256: "193", ANSI: "11"},
    Dark:  CompleteColor{TrueColor: "#d75fee", ANSI256: "163", ANSI: "5"},
}
```

## Inline Formatting

Lip Gloss supports the usual ANSI text formatting options:

```mojo
var style = Style.new().
    Bold(True).
    Italic(True).
    Faint(True).
    Blink(True).
    Strikethrough(True).
    Underline(True).
    Reverse(True)
```

## Block-Level Formatting

Lip Gloss also supports rules for block-level formatting:

```mojo
# Padding
var style = Style.new().
    PaddingTop(2).
    PaddingRight(4).
    PaddingBottom(2).
    PaddingLeft(4)

# Margins
var style = Style.new().
    MarginTop(2).
    MarginRight(4).
    MarginBottom(2).
    MarginLeft(4)
```

There is also shorthand syntax for margins and padding, which follows the same
format as CSS:

```mojo
# 2 cells on all sides
Style.new().Padding(2)

# 2 cells on the top and bottom, 4 cells on the left and right
Style.new().Margin(2, 4)

# 1 cell on the top, 4 cells on the sides, 2 cells on the bottom
Style.new().Padding(1, 4, 2)

# Clockwise, starting from the top: 2 cells on the top, 4 on the right, 3 on
# the bottom, and 1 on the left
Style.new().Margin(2, 4, 3, 1)
```

## Aligning Text

You can align paragraphs of text to the left, right, or center.

```mojo
var style = Style.new().
    Width(24).
    Align(lipgloss.Left).  # align it left
    Align(lipgloss.Right). # no wait, align it right
    Align(lipgloss.Center) # just kidding, align it in the center
```

## Width and Height

Setting a minimum width and height is simple and straightforward.

```mojo
var style = Style.new().
    SetString("What’s for lunch?").
    Width(24).
    Height(32).
    foreground("63"))
```

## Borders

Adding borders is easy:

```mojo
# Add a purple, rectangular border
var style = Style.new().
    border(lipgloss.NormalBorder()).
    border_foreground("63"))

# Set a rounded, yellow-on-purple border to the top and left
var another_style = Style.new().
    border(lipgloss.RoundedBorder()).
    border_foreground("228")).
    border_background("63")).
    border_top(True).
    border_left(True)

# Make your own border
var my_cute_border = Border(
    Top:         "._.:*:",
    Bottom:      "._.:*:",
    Left:        "|*",
    Right:       "|*",
    TopLeft:     "*",
    TopRight:    "*",
    BottomLeft:  "*",
    BottomRight: "*",
)
}
```

There are also shorthand functions for defining borders, which follow a similar
pattern to the margin and padding shorthand functions.

```mojo
# Add a thick border to the top and bottom
Style.new().
    border(thick_border(), True, False)

# Add a double border to the top and left sides. Rules are set clockwise
# from top.
Style.new().
    border(double_border(), True, False, False, True)
```

For more on borders see [the docs][docs].

## Copying Styles

Just use `copy()`:

```mojo
var style = Style.new().foreground("219")

var wildStyle = style.Copy().Blink(True)
```

`Copy()` performs a copy on the underlying data structure ensuring that you get
a True, dereferenced copy of a style. Without copying, it's possible to mutate
styles.

## Inheritance

Styles can inherit rules from other styles. When inheriting, only unset rules
on the receiver are inherited.

```mojo
var styleA = Style.new().
    foreground("229").
    background("63")

# Only the background color will be inherited here, because the foreground
# color will have been already set:
var styleB = Style.new().
    foreground("201").
    Inherit(styleA)
```

## Unsetting Rules

All rules can be unset:

```mojo
var style = Style.new().
    bold(True).                        # make it bold
    unset_bold().                       # jk don't make it bold
    background("227"). # yellow background
    unset_background()                  # never mind
```

When a rule is unset, it won't be inherited or copied.

## Enforcing Rules

Sometimes, such as when developing a component, you want to make sure style
definitions respect their intended purpose in the UI. This is where `Inline`
and `MaxWidth`, and `MaxHeight` come in:

```mojo
# Force rendering onto a single line, ignoring margins, padding, and borders.
someStyle.Inline(True).render("yadda yadda")

# Also limit rendering to five cells
someStyle.Inline(True).MaxWidth(5).render("yadda yadda")

# Limit rendering to a 5x5 cell block
someStyle.MaxWidth(5).MaxHeight(5).render("yadda yadda")
```

## Tabs

The tab character (`\t`) is rendered differently in different terminals (often
as 8 spaces, sometimes 4). Because of this inconsistency, Lip Gloss converts
tabs to 4 spaces at render time. This behavior can be changed on a per-style
basis, however:

```mojo
style := Style.new() # tabs will render as 4 spaces, the default
style = style.TabWidth(2)    # render tabs as 2 spaces
style = style.TabWidth(0)    # remove tabs entirely
style = style.TabWidth(lipgloss.NoTabConversion) # leave tabs intact
```

## Rendering

Generally, you just call the `render(string...)` method on a `lipgloss.Style`:

```mojo
style := Style.new().Bold(True).SetString("Hello,")
print(style.render("kitty.")) # Hello, kitty.
print(style.render("puppy.")) # Hello, puppy.
```

But you could also use the Stringer interface:

```mojo
var style = Style.new().SetString("你好，猫咪。").Bold(True)
print(style) # 你好，猫咪。
```

### Custom Renderers

Custom renderers allow you to render to a specific outputs. This is
particularly important when you want to render to different outputs and
correctly detect the color profile and dark background status for each, such as
in a server-client situation.

```mojo
func myLittleHandler(sess ssh.Session) {
    # Create a renderer for the client.
    renderer := lipgloss.NewRenderer(sess)

    # Create a new style on the renderer.
    style := renderer.NewStyle().background(lipgloss.AdaptiveColor{Light: "63", Dark: "228"})

    # render. The color profile and dark background state will be correctly detected.
    io.WriteString(sess, style.render("Heyyyyyyy"))
}
```

For an example on using a custom renderer over SSH with [Wish][wish] see the
[SSH example][ssh-example].

## Utilities

In addition to pure styling, Lip Gloss also ships with some utilities to help
assemble your layouts.

### Joining Paragraphs

Horizontally and vertically joining paragraphs is a cinch.

```mojo
# Horizontally join three paragraphs along their bottom edges
lipgloss.JoinHorizontal(lipgloss.Bottom, paragraphA, paragraphB, paragraphC)

# Vertically join two paragraphs along their center axes
lipgloss.JoinVertical(lipgloss.Center, paragraphA, paragraphB)

# Horizontally join three paragraphs, with the shorter ones aligning 20%
# from the top of the tallest
lipgloss.JoinHorizontal(0.2, paragraphA, paragraphB, paragraphC)
```

### Measuring Width and Height

Sometimes you’ll want to know the width and height of text blocks when building
your layouts.

```mojo
# render a block of text.
var style = Style.new().
    Width(40).
    Padding(2)
var block string = style.render(someLongString)

# Get the actual, physical dimensions of the text block.
width := lipgloss.Width(block)
height := lipgloss.Height(block)

# Here's a shorthand function.
w, h := lipgloss.Size(block)
```

### Placing Text in Whitespace

Sometimes you’ll simply want to place a block of text in whitespace.

```mojo
# Center a paragraph horizontally in a space 80 cells wide. The height of
# the block returned will be as tall as the input paragraph.
block := lipgloss.PlaceHorizontal(80, lipgloss.Center, fancyStyledParagraph)

# Place a paragraph at the bottom of a space 30 cells tall. The width of
# the text block returned will be as wide as the input paragraph.
block := lipgloss.PlaceVertical(30, lipgloss.Bottom, fancyStyledParagraph)

# Place a paragraph in the bottom right corner of a 30x80 cell space.
block := lipgloss.Place(30, 80, lipgloss.Right, lipgloss.Bottom, fancyStyledParagraph)
```

You can also style the whitespace. For details, see [the docs][docs].

### Rendering Tables

Lip Gloss ships with a table rendering sub-package.

```mojo
import "github.com/charmbracelet/lipgloss/table"
```

Define some rows of data.

```mojo
rows := [][]string{
    {"Chinese", "您好", "你好"},
    {"Japanese", "こんにちは", "やあ"},
    {"Arabic", "أهلين", "أهلا"},
    {"Russian", "Здравствуйте", "Привет"},
    {"Spanish", "Hola", "¿Qué tal?"},
}
```

Use the table package to style and render the table.

```mojo
t := table.New().
    Border(lipgloss.NormalBorder()).
    border(Style.new().foreground("99"))).
    StyleFunc(func(row, col int) lipgloss.Style {
        switch {
        case row == 0:
            return HeaderStyle
        case row%2 == 0:
            return EvenRowStyle
        default:
            return OddRowStyle
        }
    }).
    Headers("LANGUAGE", "FORMAL", "INFORMAL").
    Rows(rows...)

# You can also add tables row-by-row
t.Row("English", "You look absolutely fabulous.", "How's it going?")
```

Print the table.

```mojo
print(t)
```

![Table Example](https:#github.com/charmbracelet/lipgloss/assets/42545625/6e4b70c4-f494-45da-a467-bdd27df30d5d)

For more on tables see [the docs](https:#pkg.go.dev/github.com/charmbracelet/lipgloss?tab=doc) and [examples](https:#github.com/charmbracelet/lipgloss/tree/master/examples/table).

***

## FAQ

<details>
<summary>
Why are things misaligning? Why are borders at the wrong widths?
</summary>
<p>This is most likely due to your locale and encoding, particularly with
regard to Chinese, Japanese, and Korean (for example, <code>zh_CN.UTF-8</code>
or <code>ja_JP.UTF-8</code>). The most direct way to fix this is to set
<code>RUNEWIDTH_EASTASIAN=0</code> in your environment.</p>

<p>For details see <a href="https:#github.com/charmbracelet/lipgloss/issues/40">https:#github.com/charmbracelet/lipgloss/issues/40.</a></p>
</details>

<details>
<summary>
Why isn't Lip Gloss displaying colors?
</summary>
<p>Lip Gloss automatically degrades colors to the best available option in the
given terminal, and if output's not a TTY it will remove color output entirely.
This is common when running tests, CI, or when piping output elsewhere.</p>

<p>If necessary, you can force a color profile in your tests with
<a href="https:#pkg.go.dev/github.com/charmbracelet/lipgloss#SetColorProfile"><code>SetColorProfile</code></a>.</p>

```mojo
import (
    "github.com/charmbracelet/lipgloss"
    "github.com/muesli/termenv"
)

lipgloss.SetColorProfile(termenv.TrueColor)
```

*Note:* this option limits the flexibility of your application and can cause
ANSI escape codes to be output in cases where that might not be desired. Take
careful note of your use case and environment before choosing to force a color
profile.
</details>

## What about [Bubble Tea][tea]?

Lip Gloss doesn’t replace Bubble Tea. Rather, it is an excellent Bubble Tea
companion. It was designed to make assembling terminal user interface views as
simple and fun as possible so that you can focus on building your application
instead of concerning yourself with low-level layout details.

In simple terms, you can use Lip Gloss to help build your Bubble Tea views.

[tea]: https:#github.com/charmbracelet/tea

## Under the Hood

Lip Gloss is built on the excellent [Termenv][termenv] and [Reflow][reflow]
libraries which deal with color and ANSI-aware text operations, respectively.
For many use cases Termenv and Reflow will be sufficient for your needs.

[termenv]: https:#github.com/muesli/termenv
[reflow]: https:#github.com/muesli/reflow

## Rendering Markdown

For a more document-centric rendering solution with support for things like
lists, tables, and syntax-highlighted code have a look at [Glamour][glamour],
the stylesheet-based Markdown renderer.

[glamour]: https:#github.com/charmbracelet/glamour

## Feedback

We’d love to hear your thoughts on this project. Feel free to drop us a note!

* [Twitter](https:#twitter.com/charmcli)
* [The Fediverse](https:#mastodon.social/@charmcli)
* [Discord](https:#charm.sh/chat)

## License

[MIT](https:#github.com/charmbracelet/lipgloss/raw/master/LICENSE)

***

Part of [Charm](https:#charm.sh).

<a href="https:#charm.sh/"><img alt="The Charm logo" src="https:#stuff.charm.sh/charm-badge.jpg" width="400"></a>

Charm热爱开源 • Charm loves open source

[docs]: https:#pkg.go.dev/github.com/charmbracelet/lipgloss?tab=doc
[wish]: https:#github.com/charmbracelet/wish
[ssh-example]: examples/ssh

TODO:
* Proper rune and unicode character handling.
* Add other padding and margin functions instead of assigning each edge separately.
* Add examples.
