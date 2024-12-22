# Mog

![Mog example](https://github.com/thatstoasty/mog/blob/main/doc/images/mog.png)

Style definitions for nice terminal layouts.

* Ported from/Inspired by: <https://github.com/charmbracelet/lipgloss/tree/master>
* If you're a Go developer, please check out their CLI tooling and libraries. They're amazing!

![Mojo Version](https://img.shields.io/badge/Mojo%F0%9F%94%A5-24.6-orange)
![Build Status](https://github.com/thatstoasty/mog/actions/workflows/build.yml/badge.svg)
![Test Status](https://github.com/thatstoasty/mog/actions/workflows/test.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Installation

1. First, you'll need to configure your `mojoproject.toml` file to include my Conda channel. Add `"https://repo.prefix.dev/mojo-community"` to the list of channels.
2. Next, add `mog` to your project's dependencies by running `magic add mog`.
3. Finally, run `magic install` to install in `mog` and its dependencies. You should see the `.mojopkg` files in `$CONDA_PREFIX/lib/mojo/`.

![Mog example](https://github.com/thatstoasty/mog/blob/main/doc/images/layout.png)

Mog takes an expressive, declarative approach to terminal rendering.
Users familiar with CSS will feel at home with Mog.

```mojo
import mog

fn main():
    var style = mog.Style() \
        .bold() \
        .foreground(mog.Color(0xFAFAFA)) \
        .background(mog.Color(0x7D56F4)) \
        .padding_top(2) \
        .padding_left(4) \
        .width(22)

    print(style.render("Hello, kitty"))
```

## Colors

Mog supports the following color profiles:

### ANSI 16 colors (4-bit)

```mojo
import mog

mog.Color(5) # magenta
mog.Color(9)  # red
mog.Color(12) # light blue
```

### ANSI 256 Colors (8-bit)

```mojo
import mog

mog.Color(86)  # aqua
mog.Color(201) # hot pink
mog.Color(202) # orange
```

### True Color (16,777,216 colors; 24-bit)

```mojo
import mog

fn main():
    var color = mog.Color(0x0000FF) # good ol' 100% blue
    color = mog.Color(0x04B575) # a green
    color = mog.Color(0x3C3C3C) # a dark gray
```

...as well as a 1-bit ASCII profile, which is black and white only.

The terminal's color profile is automatically detected and colors outside
the gamut of the current palette will be automatically coerced to their closest
available value.

For now, the library assumes a dark background. You can set this to light by modifying the style's profile field.

### Adaptive Colors

You can also specify color options for light and dark backgrounds:

```mojo
import mog

fn main():
    var color = mog.AdaptiveColor(light=236, dark=248)
```

### Complete Colors

`CompleteColor` specifies exact values for `TRUE_COLOR`, `ANSI256`, and `ANSI` color
profiles.

```mojo
import mog

fn main():
    var color = mog.CompleteColor(true_color=0x0000FF, ansi256=86, ansi=5)
```

Automatic color degradation will not be performed in this case and it will be
based on the color specified.

### Complete Adaptive Colors

You can use `CompleteColor` with `AdaptiveColor` to specify the exact values for
light and dark backgrounds without automatic color degradation.

```mojo
import mog

fn main():
    var color = mog.CompleteAdaptiveColor(
        light = mog.CompleteColor(true_color=0xd7ffae, ansi256=193, ansi=11),
        dark = mog.CompleteColor(true_color=0xd75fee, ansi256=163, ansi=5),
    )

```

## Inline Formatting

`Mog` supports the usual ANSI text formatting options:

```mojo
import mog

fn main():
    var style = mog.Style() \
        .bold() \
        .italic() \
        .faint() \
        .blink() \
        .crossout() \
        .underline() \
        .reverse()
```

## Block-Level Formatting

`Mog` also supports rules for block-level formatting:

```mojo
import mog

fn main():
    # Padding
    var style = mog.Style() \
        .padding_top(2) \
        .padding_right(4) \
        .padding_bottom(2) \
        .padding_left(4)

    # Margins
    var style = mog.Style() \
        .margin_top(2) \
        .margin_right(4) \
        .margin_bottom(2) \
        .margin_left(4)
```

There is also shorthand syntax for margins and padding, which follows the same
format as CSS:

```mojo
import mog

fn main():
    # 2 cells on all sides
    var style = mog.Style().padding(2)

    # 2 cells on the top and bottom, 4 cells on the left and right
    style = mog.Style().margin(2, 4)

    # 1 cell on the top, 4 cells on the sides, 2 cells on the bottom
    style = mog.Style().padding(1, 4, 2)

    # Clockwise, starting from the top: 2 cells on the top, 4 on the right, 3 on
    # the bottom, and 1 on the left
    style = mog.Style().margin(2, 4, 3, 1)
```

## Aligning Text

You can align paragraphs of text to the left, right, or center.

```mojo
import mog

fn main():
    var style = mog.Style() \
        .width(24) \
        .align(position.left) \
        .align(position.right) \
        .align(position.center)
```

## Width and Height

Setting a minimum width and height is simple and straightforward.

```mojo
import mog

fn main():
    var style = mog.Style(value="What’s for lunch?") \
        .width(24) \
        .height(32) \
        .foreground(mog.Color(63))
```

## Borders

Adding borders is easy:

```mojo
import mog

fn main():
    # Add a purple, rectangular border
    var style = mog.Style() \
        .border(NORMAL_BORDER) \
        .border_foreground(mog.Color(63))

    # Set a rounded, yellow-on-purple border to the top and left
    var another_style = mog.Style() \
        .border(ROUNDED_BORDER) \
        .border_foreground(mog.Color(228)) \
        .border_background(mog.Color(63)) \
        .border_top(True) \
        .border_left(True)

    # Make your own border
    var my_border = Border(
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
import mog

fn main():
    # Add a thick border to the top and bottom
    var style = mog.Style().border(THICK_BORDER, True, False)

    # Add a double border to the top and left sides. Rules are set clockwise
    # from top.
    style = mog.Style().border(DOUBLE_BORDER, True, False, False, True)
```

## Unsetting Rules

All rules can be unset:

```mojo
import mog

fn main():
    var style = mog.Style() \
        .bold() \
        .unset_bold() \
        .background(mog.Color(227)) \
        .unset_background()
```

When a rule is unset, it won't be inherited or copied.

## Setting and Unsetting Rules

When a rule is set, under the hood the rule is marked as set, and then the value of the rule is stored.
When the rule is unset, the rule is marked as unset, but the value is **not** removed.

For boolean rules, such as `bold`, the rule must be set and the value must be `True` for the rule to be applied.

This leads to the following behavior:

```mojo
import mog

fn main():
    # Bold is set, and the value is set to True. Text output is bold.
    var style = mog.Style().bold()

    # Bold is set, and the value is set to False. Text output is not bold.
    var style = mog.Style().bold(False)

    # Bold is not set, and the value is set to True. Text output is not bold.
    var style = mog.Style().bold().unset_bold()

    # Bold is not set, and the value is set to False. Text output is not bold.
    var style = mog.Style().bold(False).unset_bold()
```

## Enforcing Rules

Sometimes, such as when developing a component, you want to make sure style
definitions respect their intended purpose in the UI. This is where `inline`
and `max_width`, and `max_height` come in:

```mojo
import mog

fn main():
    var style = mog.Style()
    # Force rendering onto a single line, ignoring margins, padding, and borders.
    print(style.inline().render("yadda yadda"))

    # Also limit rendering to five cells
    print(style.inline().max_width(5).render("yadda yadda"))

    # Limit rendering to a 5x5 cell block
    print(style.max_width(5).max_height(5).render("yadda yadda"))
```

* `inline` will force the text to render on a single line, ignoring margins, padding, and borders.
* `max_width` will limit the width of the rendered text, by truncating lines that are too long.
  * If you want to all lines to be a certain length, use `width` instead.
  * Lines will only be padded to the width of the widest line, and not up to `max_width`.
* `max_height` will limit the height of the rendered text, by truncating lines from the bottom of the block.
  * If you want to ensure the text is a certain height, use `height` instead.

## Tabs

The tab character (`\t`) is rendered differently in different terminals (often
as 8 spaces, sometimes 4). Because of this inconsistency, `Mog` converts
tabs to 4 spaces at render time. This behavior can be changed on a per style
basis, however:

```mojo
import mog

fn main():
    var style = mog.Style() # tabs will render as 4 spaces, the default
    style = style.tab_width(2)    # render tabs as 2 spaces
    style = style.tab_width(0)    # remove tabs entirely
    style = style.tab_width(mog.NO_TAB_CONVERSION) # leave tabs intact
```

## Rendering

You can render text with a style using the `render` method:

```mojo
import mog

fn main():
    var style = mog.Style(value="Hello,").bold()
    print(style.render("Mojo.")) # Hello, Mojo.
    print(style.render("Python.")) # Hello, Python.
    print(style.render("my", "friends.")) # Hello, my friends.
```

### Custom Renderers

Custom renderers allow you to render to a specific outputs. This is
particularly important when you want to render to different outputs and
correctly detect the color profile and dark background status for each, such as
in a server-client situation.

```mojo
import mog

fn main():
    # Create a renderer for the client.
    var custom_renderer = mog.Renderer(mog.ANSI)

    # Create a new style using the custom renderer.
    var style = mog.Style().background(mog.AdaptiveColor(light=63, dark=228))
    var custom_style = style.renderer(custom_renderer)

    # Render some output using the styles.
    # `style` uses the default renderer which will detect the color profile and dark background state.
    # `custom_style` will use the custom renderer, which has manually set the color profile to `ANSI` (0-15 color support).
    print(style.render("Automatic renderer output!"))
    print(custom_style.render("Manual renderer output!"))

```

## Utilities

`Mog` also includes utilities to assemble your layouts.

### Joining Paragraphs

Compose your text blocks easily using `join_horizontal` and `join_vertical`.

```mojo
import mog

fn main():
    var paragraph_a = "Hello, world!"
    var paragraph_b = "How are you?"
    var paragraph_c = "I'm doing well.\nThank you."

    # Horizontally join three paragraphs along their bottom edges
    mog.join_horizontal(mog.bottom, paragraph_a, paragraph_b, paragraph_c)

    # Vertically join two paragraphs along their center axes
    mog.join_vertical(mog.center, paragraph_a, paragraph_b)

    # Horizontally join three paragraphs, with the shorter ones aligning 20%
    # from the top of the tallest
    mog.join_horizontal(0.2, paragraph_a, paragraph_b, paragraph_c)
```

### Measuring Width and Height

When building layouts, you'll want to know the the width and/or height of text blocks.
`Mog` provides functions to get the dimensions of the text block, accounting for ANSI sequences
and unicode codepoints being 0-2 cells wide.

```mojo
import mog

fn main():
    # render a block of text.
    var style = mog.Style() \
        .width(40) \
        .padding(2)
    var block = style.render(some_long_string)

    # Get the actual, physical dimensions of the text block.
    var width = mog.get_width(block)
    var height = mog.get_height(block)

    # Here's a shorthand function.
    var dimensions = mog.get_dimensions(block)
```

### Placing Text in Whitespace

Sometimes you’ll simply want to place a block of text in whitespace.

```mojo
from mog import place, place_horizontal, place_vertical

fn main():
    # Center a paragraph horizontally in a space 80 cells wide. The height of
    # the block returned will be as tall as the input paragraph.
    block = place_horizontal(80, mog.center, fancy_styled_paragraph)

    # Place a paragraph at the bottom of a space 30 cells tall. The width of
    # the text block returned will be as wide as the input paragraph.
    block = place_vertical(30, mog.bottom, fancy_styled_paragraph)

    # Place a paragraph in the bottom right corner of a 30x80 cell space.
    block = place(30, 80, mog.right, mog.bottom, fancy_styled_paragraph)
```

The `place` functions use a default `Renderer`, which attempts to detect the color profile supported and assumes a dark background terminal. If you'd like to explicitly set the color profile and background, you can create your own `Renderer`, use it's `place` methods.

```mojo
import mog

fn main():
    # Set the color profile to ANSI (0-15 colors) and the background to light manually.
    var renderer = mog.Renderer(mog.ANSI, dark_background=False)
    var block = renderer.place_horizontal(80, mog.center, fancy_styled_paragraph)
    block = renderer.place_vertical(30, mog.bottom, fancy_styled_paragraph)
    block = renderer.place(30, 80, mog.right, mog.bottom, fancy_styled_paragraph)
```

### Rendering Tables

`Mog` also has a module for rendering tables.

Define some rows of data.

```mojo
import mog.table

fn main():
    var rows = List[List[String]](
        List[String]("Chinese", "您好", "你好"),
        List[String]("Japanese", "こんにちは", "やあ"),
        List[String]("Arabic", "أهلين", "أهلا"),
        List[String]("Russian", "Здравствуйте", "Привет"),
        List[String]("Spanish", "Hola", "¿Qué tal?"),
    )
    ...
```

Use the table package to style and render the table.

```mojo
import mog

fn main():
    ...
    var t = mog.Table.new().
        .border(NORMAL_BORDER) \
        .border_style(mog.Style().foreground(mog.Color(99))) \
        .headers("LANGUAGE", "FORMAL", "INFORMAL") \
        .rows(rows)

    # You can also add tables row-by-row
    t.row("English", "You look absolutely fabulous.", "How's it going?")
```

Print the table.

```mojo
print(t)
```

Here's an example table rendering!

![Mog example](https://github.com/thatstoasty/mog/blob/main/doc/tapes/pokemon.gif)

---

## TODO

* Decompose style render mega function and mega class into smaller ones.
* It seems like renderer.place_vertical renders whitespace with a width that's too long in the Ubuntu test container. Will need to investigate why this happened. It might be because the execution environment is not necessarily a terminal.

### Check out these other libraries in the Mojo Community!

* `A Mojo HTTP framework with wings` - [@saviorand/lightbug_http](https://github.com/saviorand/lightbug_http)
