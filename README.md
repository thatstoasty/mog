# Mog

Style definitions for nice terminal layouts. Built with TUIs in mind.
Ported from/Inspired by: <https://github.com/charmbracelet/lipgloss/tree/master>

If you're a Go developer, please check out their CLI tooling and libraries. They're unmatched!

![Lip Gloss example](https://github.com/thatstoasty/mog/blob/main/layout.png)

Lip Gloss takes an expressive, declarative approach to terminal rendering.
Users familiar with CSS will feel at home with Lip Gloss.

```mojo

from mog import Style

var style = Style.new(). \
    bold(True). \
    foreground("#FAFAFA"). \
    background("#7D56F4"). \
    padding_top(2). \
    padding_left(4). \
    width(22)

print(style.render("Hello, kitty"))
```

## Colors

Lip Gloss supports the following color profiles:

### ANSI 16 colors (4-bit)

```mojo
5")  # magenta
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
mog.AdaptiveColor(light="236", dark="248")
```

The terminal's background color will automatically be detected and the
appropriate color will be chosen at runtime.

### Complete Colors

CompleteColor specifies exact values for truecolor, ANSI256, and ANSI color
profiles.

```mojo
mog.CompleteColor(true_color="#0000FF", ansi256="86", ansi="5")
```

Automatic color degradation will not be performed in this case and it will be
based on the color specified.

### Complete Adaptive Colors

You can use CompleteColor with AdaptiveColor to specify the exact values for
light and dark backgrounds without automatic color degradation.

```mojo
mog.CompleteAdaptiveColor(
    light = mog.CompleteColor(true_color: "#d7ffae", ansi256: "193", ansi: "11"),
    dark = mog.CompleteColor(true_color: "#d75fee", ansi256: "163", ansi: "5"),
)

```

## Inline Formatting

Lip Gloss supports the usual ANSI text formatting options:

```mojo
var style = Style.new().
    bold(True).
    italic(True).
    faint(True).
    blink(True).
    strikethrough(True).
    underline(True).
    reverse(True)
```

## Block-Level Formatting

Lip Gloss also supports rules for block-level formatting:

```mojo
# Padding
var style = Style.new().
    padding_top(2).
    padding_right(4).
    padding_bottom(2).
    padding_left(4)

# Margins
var style = Style.new().
    margin_top(2).
    margin_right(4).
    margin_bottom(2).
    margin_left(4)
```

There is also shorthand syntax for margins and padding, which follows the same
format as CSS:

```mojo
# 2 cells on all sides
Style.new().padding(2)

# 2 cells on the top and bottom, 4 cells on the left and right
Style.new().margin(2, 4)

# 1 cell on the top, 4 cells on the sides, 2 cells on the bottom
Style.new().padding(1, 4, 2)

# Clockwise, starting from the top: 2 cells on the top, 4 on the right, 3 on
# the bottom, and 1 on the left
Style.new().margin(2, 4, 3, 1)
```

## Aligning Text

You can align paragraphs of text to the left, right, or center.

```mojo
var style = Style.new() \
    width(24) \
    align(position.left)  # align it left
    align(position.right) # no wait, align it right
    align(position.center) # just kidding, align it in the center
```

## Width and Height

Setting a minimum width and height is simple and straightforward.

```mojo
var style = Style.new() \
    .set_string("What’s for lunch?") \
    .width(24) \
    .height(32) \
    .foreground(mog.Color("63"))
```

## Borders

Adding borders is easy:

```mojo
# Add a purple, rectangular border
var style = Style.new().
    border(normal_border()).
    border_foreground(mog.Color("63"))

# Set a rounded, yellow-on-purple border to the top and left
var another_style = Style.new() \
    border(rounded_border()) \
    border_foreground(mog.Color("228")) \
    border_background(mog.Color("63")) \
    border_top(True) \
    border_left(True)

# Make your own border
var my_cute_border = Border(
    top             = "._.:*:",
    bottom          = "._.:*:",
    left            = "|*",
    right           = "|*",
    top_left        = "*",
    top_right       = "*",
    bottom_left     = "*",
    bottom_right    = "*",
)
```

There are also shorthand functions for defining borders, which follow a similar
pattern to the margin and padding shorthand functions.

```mojo
# Add a thick border to the top and bottom
Style.new().
rder(thick_border(), True, False)

# Add a double border to the top and left sides. Rules are set clockwise
# from top.
Style.new().
    border(double_border(), True, False, False, True)
```

## Copying Styles

Just use `copy()`:

```mojo
var style = Style.new().foreground(mog.Color("219")) \

var wild_style = style.copy().blink(True)
```

`copy()` performs a copy on the underlying data structure ensuring that you get
a True, dereferenced copy of a style. Without copying, it's possible to mutate
styles.

## Inheritance

Styles can inherit rules from other styles. When inheriting, only unset rules
on the receiver are inherited.

```mojo
var style_a = Style.new(). \
    foreground(mog.Color("229")). \
    background(mog.Color("63"))

# Only the background color will be inherited here, because the foreground
# color will have been already set:
var style_b = Style.new(). \
    foreground(mog.Color("201")). \
    inherit(style_a)
```

## Unsetting Rules

All rules can be unset:

```mojo
var style = Style.new().
    bold(True).                        # make it bold
    unset_bold().                       # jk don't make it bold
    background(mog.Color("227")). # yellow background
    unset_background()                  # never mind
```

When a rule is unset, it won't be inherited or copied.

## Enforcing Rules

Sometimes, such as when developing a component, you want to make sure style
definitions respect their intended purpose in the UI. This is where `inline`
and `max_width`, and `max_height` come in:

```mojo
# Force rendering onto a single line, ignoring margins, padding, and borders.
some_style.inline(True).render("yadda yadda")

# Also limit rendering to five cells
some_style.inline(True).max_width(5).render("yadda yadda")

# Limit rendering to a 5x5 cell block
some_style.max_width(5).max_height(5).render("yadda yadda")
```

## Tabs

The tab character (`\t`) is rendered differently in different terminals (often
as 8 spaces, sometimes 4). Because of this inconsistency, Lip Gloss converts
tabs to 4 spaces at render time. This behavior can be changed on a per-style
basis, however:

```mojo
style = Style.new() # tabs will render as 4 spaces, the default
style = style.tab_width(2)    # render tabs as 2 spaces
style = style.tab_width(0)    # remove tabs entirely
style = style.tab_width(mog.NO_TAB_CONVERSION) # leave tabs intact
```

## Rendering

Generally, you just call the `render(string...)` method on a `mog.Style`:

```mojo
style = Style.new().bold(True).set_string("Hello,")
print(style.render("kitty.")) # Hello, kitty.
print(style.render("puppy.")) # Hello, puppy.
```

But you could also use the Stringer interface:

```mojo
var style = Style.new().set_string("你好，猫咪。").bold(True)
print(style) # 你好，猫咪。
```

### Custom Renderers

Custom renderers allow you to render to a specific outputs. This is
particularly important when you want to render to different outputs and
correctly detect the color profile and dark background status for each, such as
in a server-client situation.

```mojo
fn my_little_handler():
    # Create a renderer for the client.
    renderer = lipgloss.new_renderer()

    # Create a new style on the renderer.
    style = renderer.new_style().background(mog.AdaptiveColor(light="63", dark="228"))

    # render. The color profile and dark background state will be correctly detected.
    style.render("Heyyyyyyy")

```

## Utilities

In addition to pure styling, Lip Gloss also ships with some utilities to help
assemble your layouts.

### Joining Paragraphs

Horizontally and vertically joining paragraphs is a cinch.

```mojo
# Horizontally join three paragraphs along their bottom edges
join_horizontal(bottom, paragraph_a, paragraph_b, paragraph_c)

# Vertically join two paragraphs along their center axes
join_vertical(center, paragraph_a, paragraph_b)

# Horizontally join three paragraphs, with the shorter ones aligning 20%
# from the top of the tallest
join_horizontal(0.2, paragraph_a, paragraph_b, paragraph_c)
```

### Measuring Width and Height

Sometimes you’ll want to know the width and height of text blocks when building
your layouts.

```mojo
# render a block of text.
var style = Style.new(). \
    width(40). \
    padding(2)
var block string = style.render(some_long_string)

# Get the actual, physical dimensions of the text block.
width = mog.get_width(block)
height = mog.get_height(block)

# Here's a shorthand function.
w, h = mog.get_size(block)
```

### Placing Text in Whitespace

Sometimes you’ll simply want to place a block of text in whitespace.

```mojo
# Center a paragraph horizontally in a space 80 cells wide. The height of
# the block returned will be as tall as the input paragraph.
block = place_horizontal(80, mog.center, fancy_styled_paragraph)

# Place a paragraph at the bottom of a space 30 cells tall. The width of
# the text block returned will be as wide as the input paragraph.
block = place_vertical(30, mog.bottom, fancy_styled_paragraph)

# Place a paragraph in the bottom right corner of a 30x80 cell space.
block = place(30, 80, mog.right, mog.bottom, fancy_styled_paragraph)
```

### Rendering Tables

Lip Gloss ships with a table rendering sub-package.

```mojo
import mog.table
```

Define some rows of data.

```mojo
rows = List[List[String]](
    List[String]("Chinese", "您好", "你好"),
    List[String]("Japanese", "こんにちは", "やあ"),
    List[String]("Arabic", "أهلين", "أهلا"),
    List[String]("Russian", "Здравствуйте", "Привет"),
    List[String]("Spanish", "Hola", "¿Qué tal?"),
)
```

Use the table package to style and render the table.

```mojo
t = table.new_table().
    border(normal_border()) \
    border_style(Style.new().foreground(mog.Color("99"))) \
    style_func(func(row, col int) lipgloss.Style {
        switch {
        case row == 0:
            return header_style
        case row%2 == 0:
            return even_row_style
        default:
            return odd_row_style
        }
    }).
    headers("LANGUAGE", "FORMAL", "INFORMAL").
    rows(rows)

# You can also add tables row-by-row
t.Row("English", "You look absolutely fabulous.", "How's it going?")
```

Print the table.

```mojo
print(t)
```

![Table Example](https:#github.com/charmbracelet/lipgloss/assets/42545625/6e4b70c4-f494-45da-a467-bdd27df30d5d)

For more on tables see [the docs](https:#pkg.go.dev/github.com/charmbracelet/lipgloss?tab=doc) and [examples](https:#github.com/charmbracelet/lipgloss/tree/master/examples/table).

---

## FAQ

```mojo
import (
    "github.com/charmbracelet/lipgloss"
    "github.com/muesli/termenv"
)

```

TODO:

- Decompose style render mega function and mega class into smaller ones.
- Figure out capturing variables in table style functions. Using escaping and capturing crashes, and creating the style each time the function is called is slow.
- Fix table top and bottom rendering. Fire emoji border example renders those lengths incorrectly.
