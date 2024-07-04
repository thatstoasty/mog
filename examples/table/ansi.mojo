import mog


fn main():
    var s = mog.new_style().foreground(mog.Color(240))

    var t = mog.new_table()
    t.width = 50
    t.row("Bubble Tea", s.render("Milky"))
    t.row("Milk Tea", s.render("Also milky"))
    t.row("Actual milk", s.render("Milky as well"))
    print(t.render())
