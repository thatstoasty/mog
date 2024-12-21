import mog


fn main():
    var s = mog.Style().foreground(mog.Color(240))

    var table = mog.Table.new()
    table.width = 50
    table = (
        table.row("Bubble Tea", s.render("Milky"))
        .row("Milk Tea", s.render("Also milky"))
        .row("Actual milk", s.render("Milky as well"))
    )
    print(table)
