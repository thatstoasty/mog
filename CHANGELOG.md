# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased] - yyyy-mm-dd

## [0.4.0] - Unreleased

Requires Mojo `1.2.0` and `mist` `v0.4.0`.

This release renames a number of public types and constants. The sections below
give the old spelling for each one.

### Changed

- `AnyTerminalColor` is now named `TerminalColor`, and is an enum rather than a
  wrapper around a `Variant`. Each `mog` color type has a case of its own and
  still converts into one implicitly, so passing a color to a `Style` is
  unchanged.
- The border presets are members of `Border` instead of module-level constants:
  `ROUNDED_BORDER` becomes `Border.ROUNDED`, `NORMAL_BORDER` becomes
  `Border.NORMAL`, and so on for `ASCII`, `STAR`, `PLUS`, `BLOCK`,
  `OUTER_HALF_BLOCK`, `INNER_HALF_BLOCK`, `THICK`, `DOUBLE` and `HIDDEN`.
  `NO_BORDER` becomes `Border.EMPTY`.
- `Emphasis`, `Axis`, `Side` and `PropKey` are enums, and their cases are
  lowercase: `Emphasis.BOLD` becomes `Emphasis.bold`, `Axis.HORIZONTAL` becomes
  `Axis.horizontal`. `Position`'s constants are unchanged.
- Case inference does not reach through `Optional`, so an `Optional[Emphasis]`
  argument needs the type named: `Style(emphasis=Emphasis.bold)`, not
  `Style(emphasis=.bold)`.
- Sizes are `UInt` rather than `UInt16` throughout. This covers `get_width`,
  `get_height` and `get_dimensions`, the `Style` size setters, `Padding`,
  `Margin` and the table's column widths.
- `Padding` and `Margin` take `x` and `y` for their two-axis constructor,
  previously `x_width` and `y_width`.
- `Style.text_alignment` takes the axis as a keyword argument:
  `text_alignment(Position.LEFT, axis=.horizontal)`, previously
  `text_alignment(Axis.HORIZONTAL, Position.LEFT)`. The one-argument and
  two-argument overloads are unchanged.
- `align_text_horizontal` and `align_text_vertical` now honour any `Position`,
  not only the named constants. See **Fixed**.

### Removed

- The `TerminalColor` trait. The name now refers to the enum described above,
  which every `mog` color type converts into.
- `AnyTerminalColor.isa`, `AnyTerminalColor.__getitem_param__` and
  `AnyTerminalColor.is_same_type`. These existed to reach inside the `Variant`;
  use `match` on the enum, or `is_no_color()` for the common check.
- `Equatable` from `Emphasis`, `Axis` and `Side`, which cannot derive `__eq__`
  as enums. Use `match` instead of `==`. `PropKey` remains `Equatable`.

### Fixed

- Setting a rule whose default is on no longer leaves it on.
  `color_whitespace(False)`, `underline_spaces(False)` and
  `strikethrough_spaces(False)` were recorded as "never set" and fell back to
  their default, so they rendered identically to the `True` case.
- `align_text_horizontal` and `align_text_vertical` dropped their padding
  entirely for any `Position` other than the five named constants, leaving the
  text short of the requested width or height. A `Style` built with
  `width(8).text_alignment(Position(0.25), axis=.horizontal)` rendered 2 columns
  wide. The padding is now split in proportion to the position, as `join` and
  `WhitespaceRenderer.place_horizontal` already did.
- `render_horizontal_edge` overshot the requested width when the border's middle
  was more than one cell wide, because it emitted the whole middle per pass and
  only checked the width between passes. A `-=` middle at width 10 came out 12
  cells wide.

### Performance

- `join_horizontal` and `join_vertical` carry each line as a slice of their
  input instead of copying it into an owned `String`. Joining three twenty line
  panels went from 7.5us to 3.3us.
- `render_horizontal_edge` splits the border's middle into characters once
  rather than once per cell of the edge. An 80 cell edge went from 14.4us to
  6.1us, and a bordered block renders two of them.

### Added

- Benchmarks for the two ways of configuring a `Style`: `StyleBuildChained`,
  `StyleBuildConstructor` and `StyleModifyChained`. Setters copy the style once
  per call, which makes a chain roughly 4x the cost of the equivalent
  constructor call, though both are small next to a render.

## [0.3.3] - 2026-09-17

Requires Mojo `1.1.0` and `mist` `v0.3.5`.

- Adopted the `String(capacity_bytes=...)` constructor, replacing the renamed
  `capacity` argument.
- Replaced a `@parameter` nested closure in the table with a plain conditional,
  following the unified closure changes.
