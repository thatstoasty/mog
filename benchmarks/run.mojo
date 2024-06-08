import benchmark
from benchmarks.layout import render_layout
from benchmarks.basic_styling import basic_styling, basic_styling_big_file
import mog


fn table_styling(row: Int, col: Int) -> mog.Style:
    var style = mog.new_style().horizontal_alignment(mog.center).vertical_alignment(mog.center).padding(0, 1)
    var header_style = style.copy().foreground(mog.Color("#39E506"))
    if row == 0:
        return header_style
    else:
        return style


fn main():
    var results = mog.new_table()
    results.style_function = table_styling
    results.set_headers("Name", "Mean (ms)", "Total (ms)", "Iterations", "Warmup Total", "Warmup Iterations")

    var report = benchmark.run[render_layout](max_iters=10)
    results.row(
        "Render layout",
        str(report.mean(benchmark.Unit.ms)),
        str(report.duration(benchmark.Unit.ms)),
        str(report.iters()),
        str(report.warmup_duration / 1e6),
        str(report.warmup_iters),
    )

    var bs_report = benchmark.run[basic_styling](max_iters=10)
    results.row(
        "Basic styling",
        str(bs_report.mean(benchmark.Unit.ms)),
        str(bs_report.duration(benchmark.Unit.ms)),
        str(bs_report.iters()),
        str(bs_report.warmup_duration / 1e6),
        str(bs_report.warmup_iters),
    )

    # var bs_big_report = benchmark.run[basic_styling_big_file](max_iters=10)
    # results.row("Large file test", str(bs_big_report.mean(benchmark.Unit.ms)), str(bs_big_report.duration(benchmark.Unit.ms)), str(bs_big_report.iters()), str(bs_big_report.warmup_duration / 1e6), str(bs_big_report.warmup_iters))

    print(results.render())
