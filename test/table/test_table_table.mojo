# import testing
# import mog
# from mog.table import Table


# def test_table_render():
#     var s = mog.Style(mog.ANSI).foreground(mog.Color(240))
#     var table = Table.new().row("Bubble Tea", s.render("Milky"))
#     table.width = 50
#     print(table)
#     testing.assert_equal(
#         "str(table)",
#         "Bubble Tea Milky\nMilk Tea Also milky\nActual milk Milky as well\n",
#     )