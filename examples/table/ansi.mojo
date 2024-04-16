from mog import Style, Border, Table, center, default_styles, new_string_data, new_table
import mog


fn main() raises:
    var s = Style.new().foreground(mog.Color("240"))

    var t = new_table()
    t.width = 50
    t.row("Bubble Tea", s.render("Milky"))
    t.row("Milk Tea", s.render("Also milky"))
    t.row("Actual milk", s.render("Milky as well"))
    print(t.render())
