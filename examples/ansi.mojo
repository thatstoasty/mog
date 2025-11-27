import mog


fn main():
    var s = mog.Style(foreground=mog.Color(240))
    var table = mog.Table(
        width=50,
        data=mog.Data(
            ["Mistborn", s.render("Great")],
            ["The Will of the Many", s.render("Excellent")],
            ["Wheel of Time", s.render("Fantastic")],
        )
    )
    print(table)
