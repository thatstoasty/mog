# Mog

![Mojo 24.4](https://img.shields.io/badge/Mojo%F0%9F%94%A5-24.4-purple)

Style definitions for nice terminal layouts. Built with TUIs in mind.
Ported from/Inspired by: <https://github.com/charmbracelet/lipgloss/tree/master>

If you're a Go developer, please check out their CLI tooling and libraries. They're unmatched!

For bugs and todos, see the bottom of the readme. At the moment, characters with a printable length greater than 1 ARE NOT supported.

You should be able to build the package by running `mojo package mog -I external`. For the easiest usage method, I recommend just copying the entire external folder into your repository, then copy the `mog` folder into the external folder as well.

> NOTE: It seems like `.mojopkg` files don't like being part of another package, eg. sticking all of your external deps in an `external` or `vendor` package. The only way I've gotten mojopkg files to work is to be in the same directory as the file being executed, and that directory cannot be a mojo package.

![Mog example](https://github.com/thatstoasty/mog/blob/main/layout.png)

Mog takes an expressive, declarative approach to terminal rendering.
Users familiar with CSS will feel at home with Mog.

```mojo

import mog

var style = mog.new_style() \
    .bold(True) \
    .foreground(mog.Color("#FAFAFA")) \
    .background(mog.Color("#7D56F4")) \
    .padding_top(2) \
    .padding_left(4) \
    .width(22)

print(style.render("Hello, kitty"))
```

## Colors

Mog supports the following color profiles:

### ANSI 16 colors (4-bit)

```mojo
mog.Color("5") # magenta
mog.Color("9")  # red
mog.Color("12") # light blue
```

### ANSI 256 Colors (8-bit)

```mojo
mog.Color("86")  # aqua
mog.Color("201") # hot pink
mog.Color("202") # orange
```

### True Color (16,777,216 colors; 24-bit)

```mojo
mog.Color("#0000FF") # good ol' 100% blue
mog.Color("#04B575") # a green
mog.Color("#3C3C3C") # a dark gray
```

...as well as a 1-bit ASCII profile, which is black and white only.

The terminal's color profile will soon be automatically detected, and colors outside
the gamut of the current palette will be automatically coerced to their closest
available value.

For now, the library assumes a dark background. You can set this to light by modifying the style's profile field.

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

Mog supports the usual ANSI text formatting options:

```mojo
var style = mog.new_style() \
    .bold(True) \
    .italic(True) \
    .faint(True) \
    .blink(True) \
    .crossout(True) \
    .underline(True) \
    .reverse(True)
```

## Block-Level Formatting

Mog also supports rules for block-level formatting:

```mojo
# Padding
var style = mog.new_style() \
    .padding_top(2) \
    .padding_right(4) \
    .padding_bottom(2) \
    .padding_left(4)

# Margins
var style = mog.new_style() \
    .margin_top(2) \
    .margin_right(4) \
    .margin_bottom(2) \
    .margin_left(4)
```

There is also shorthand syntax for margins and padding, which follows the same
format as CSS:

```mojo
# 2 cells on all sides
mog.new_style().padding(2)

# 2 cells on the top and bottom, 4 cells on the left and right
mog.new_style().margin(2, 4)

# 1 cell on the top, 4 cells on the sides, 2 cells on the bottom
mog.new_style().padding(1, 4, 2)

# Clockwise, starting from the top: 2 cells on the top, 4 on the right, 3 on
# the bottom, and 1 on the left
mog.new_style().margin(2, 4, 3, 1)
```

## Aligning Text

You can align paragraphs of text to the left, right, or center.

```mojo
var style = mog.new_style() \
    .width(24) \
    .align(position.left) \ # align it left
    .align(position.right) \ # no wait, align it right
    .align(position.center) # just kidding, align it in the center
```

## Width and Height

Setting a minimum width and height is simple and straightforward.

```mojo
var style = mog.new_style() \
    .set_string("What’s for lunch?") \
    .width(24) \
    .height(32) \
    .foreground(mog.Color("63"))
```

## Borders

Adding borders is easy:

```mojo
# Add a purple, rectangular border
var style = mog.new_style() \
    .border(normal_border()) \
    .border_foreground(mog.Color("63"))

# Set a rounded, yellow-on-purple border to the top and left
var another_style = mog.new_style() \
    .border(rounded_border()) \
    .border_foreground(mog.Color("228")) \
    .border_background(mog.Color("63")) \
    .border_top(True) \
    .border_left(True)

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
mog.new_style().border(thick_border(), True, False)

# Add a double border to the top and left sides. Rules are set clockwise
# from top.
mog.new_style().border(double_border(), True, False, False, True)
```

## Copying Styles

Just use `copy()`:

```mojo
var style = mog.new_style().foreground(mog.Color("219"))

var wild_style = style.copy().blink(True)
```

`copy()` performs a copy on the underlying data structure ensuring that you get
a True, dereferenced copy of a style. Without copying, it's possible to mutate
styles.

## Unsetting Rules

All rules can be unset:

```mojo
var style = mog.new_style() \
    .bold(True) \                       # make it bold
    .unset_bold() \                     # jk don't make it bold
    .background(mog.Color("227")) \     # yellow background
    .unset_background()                  # never mind
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
as 8 spaces, sometimes 4). Because of this inconsistency, Mog converts
tabs to 4 spaces at render time. This behavior can be changed on a per-style
basis, however:

```mojo
style = mog.new_style() # tabs will render as 4 spaces, the default
style = style.tab_width(2)    # render tabs as 2 spaces
style = style.tab_width(0)    # remove tabs entirely
style = style.tab_width(mog.NO_TAB_CONVERSION) # leave tabs intact
```

## Rendering

Generally, you just call the `render(string)` method on a `mog.Style`:

```mojo
style = mog.new_style().bold(True).set_string("Hello,")
print(style.render("kitty.")) # Hello, kitty.
print(style.render("puppy.")) # Hello, puppy.
print(style.render("my", "puppy.")) # Hello, my puppy.
```

But you could also use the Stringer interface:

```mojo
var style = mog.new_style().set_string("你好，猫咪。").bold(True)
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

In addition to pure styling, Mog also ships with some utilities to help
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
var style = mog.new_style() \
    .width(40) \
    .padding(2)
var block string = style.render(some_long_string)

# Get the actual, physical dimensions of the text block.
width = mog.get_width(block)
height = mog.get_height(block)

# Here's a shorthand function.
var width = 0
var height = 0
width, height = mog.get_size(block)
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

Mog ships with a table rendering sub-package.

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
    .border(normal_border()) \
    .border_style(mog.new_style().foreground(mog.Color("99"))) \
    .headers("LANGUAGE", "FORMAL", "INFORMAL") \
    .rows(rows)

# You can also add tables row-by-row
t.row("English", "You look absolutely fabulous.", "How's it going?")
```

Print the table.

```mojo
print(t)
```

---

## TODO

- Decompose style render mega function and mega class into smaller ones.
- Figure out capturing variables in table style functions. Using escaping and capturing crashes, and creating the style each time the function is called is slow.
- Code cannot handle characters with a printable length greater than 1.
- It seems like renderer.place_vertical renders whitespace with a width that's too long in the Ubuntu test container. Will need to investigate why this happened. It might be because the execution environment is not necessarily a terminal.

## Notes

- ANSI256's support of setting both foreground and background colors is limited. It's possible to set both, but often the foreground color will be ignored.
