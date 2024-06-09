from benchmarks.basic_styling import basic_styling_big_file
from external.gojo.strings import StringBuilder
import mog


fn main():
    var content: String = ""
    try:
        with open("/Users/mikhailtavarez/Git/mojo/mog/benchmarks/data/big.txt", "r") as file:
            # with open("./benchmarks/data/big.txt", "r") as file:
            content = file.read()
            # basic_styling_big_file()
            var style = mog.new_style().bold(True).foreground(mog.Color("#FAFAFA")).background(
                mog.Color("#7D56F4")
            ).width(100)
            var builder = StringBuilder()
            # for _ in range(5):
            #     _ = builder.write_string(style.render("Hello "))
            _ = builder.write_string(style.render(content))
            # _ = builder.write_string(content)
            print("first builder should bdestroyed")
            print(str(builder))
    except e:
        print(e)

    # # basic_styling_big_file()
    # var style = mog.new_style().bold(True).foreground(mog.Color("#FAFAFA")).background(mog.Color("#7D56F4")).width(100)
    # var builder = StringBuilder()
    # # for _ in range(5):
    # #     _ = builder.write_string(style.render("Hello "))
    # # _ = builder.write_string(style.render("Hello "))
    # _ = builder.write_string(content)
    # print("first builder should bdestroyed")
    # print(str(builder))
