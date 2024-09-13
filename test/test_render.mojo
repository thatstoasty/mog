import testing
import mog


def test_unicode_handling():
    alias a: String = "Hello──World!"
    print(
        mog.Style()
        .faint()
        .border(mog.ROUNDED_BORDER)
        .render(mog.Style().border(mog.ROUNDED_BORDER).underline().foreground(mog.Color(0xFAFAFA)).render(a))
    )
    # print(mog.Style().border(mog.ROUNDED_BORDER).underline().foreground(mog.Color(0xFAFAFA)).render(a).split("\n").__str__())

    # testing.assert_equal(mog.Style().border(mog.ROUNDED_BORDER).underline().foreground(mog.Color(0xFAFAFA)).render(a), "\x1B[;94mHello──World!\x1B[0m")
