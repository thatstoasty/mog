from .style import osc, st


fn notify(title: String, body: String):
    print_no_newline(osc + "777;notify;" + title + ";" + body + st)
