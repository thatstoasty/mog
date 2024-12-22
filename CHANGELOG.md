# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased] - yyyy-mm-dd

## [0.1.7] - 2024-12-18

- Remove `gojo` dependencies, any usage of `StringBuilder` now uses String streaming.
- Made `Style.render()` more flexible by accepting `Writable` types, instead of just `String`.
- Cleaned up any additional allocations being made by using `StringSlice` where possible.

## [0.1.6] - 2024-09-13

- Added a Moogle example and revised the readme. Pulled in upstream `mist` and `hue` changes for compatability improvments.
- Updated the `layout` example to include color grids.
