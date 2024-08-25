from tests.wrapper import MojoTest
import mog


fn test_unicode_handling() raises:
    var test = MojoTest("Testing unicode handling")
    alias a: String = "Hello──World!"
    print(
        mog.Style()
        .faint()
        .border(mog.ROUNDED_BORDER)
        .render(mog.Style().border(mog.ROUNDED_BORDER).underline().foreground(mog.Color(0xFAFAFA)).render(a))
    )
    # print(mog.Style().border(mog.ROUNDED_BORDER).underline().foreground(mog.Color(0xFAFAFA)).render(a).split("\n").__str__())

    # test.assert_equal(mog.Style().border(mog.ROUNDED_BORDER).underline().foreground(mog.Color(0xFAFAFA)).render(a), "\x1B[;94mHello──World!\x1B[0m")


fn main() raises:
    test_unicode_handling()
