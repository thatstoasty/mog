import testing
from mog import join_horizontal, join_vertical, Position


def test_horizontal_join():
    alias a = "Hello World!\nThis is an example."
    alias b = "I could be more creative.\nBut, I'm out of ideas."

    # Test horizontally joining three paragraphs along their bottom edges
    var bottom_aligned = join_horizontal(Position.BOTTOM, a, b)
    # print(bottom_aligned)

    testing.assert_equal(
        bottom_aligned,
        "Hello World!       I could be more creative.\nThis is an example.But, I'm out of ideas.   ",
    )

    var top_aligned = join_horizontal(Position.TOP, a, b)
    # print(top_aligned)

    testing.assert_equal(
        top_aligned,
        "Hello World!       I could be more creative.\nThis is an example.But, I'm out of ideas.   ",
    )

    var center_aligned = join_horizontal(Position.CENTER, a, b)
    # print(center_aligned)

    testing.assert_equal(
        center_aligned,
        "Hello World!       I could be more creative.\nThis is an example.But, I'm out of ideas.   ",
    )


def test_vertical_join():
    alias a = "Hello World!\nThis is an example."
    alias b = "I could be more creative.\nBut, I'm out of ideas."

    # Test vertically joining two paragraphs along their right border
    var right_aligned = join_vertical(Position.RIGHT, a, b)
    # print(right_aligned)
    testing.assert_equal(
        right_aligned,
        "             Hello World!\n      This is an example.\nI could be more creative.\n   But, I'm out of ideas.",
    )

    # Test vertically joining two paragraphs along their left border
    var left_aligned = join_vertical(Position.LEFT, a, b)
    # print(left_aligned)
    testing.assert_equal(
        left_aligned,
        "Hello World!             \nThis is an example.      \nI could be more creative.\nBut, I'm out of ideas.   ",
    )

    # Test vertically joining two paragraphs along their center axis
    var center_aligned = join_vertical(Position.CENTER, a, b)
    # print(center_aligned)
    testing.assert_equal(
        center_aligned,
        "      Hello World!       \n   This is an example.   \nI could be more creative.\n But, I'm out of ideas.  ",
    )
