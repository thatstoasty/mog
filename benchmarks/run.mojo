import benchmark
from benchmark import ThroughputMeasure, BenchMetric, Bencher, Bench, BenchId, BenchConfig
from functions.layout import render_layout
from functions.basic_styling import (
    basic_styling,
    basic_styling_big_file,
    basic_comptime_styling,
)
import mog
import pathlib

# fn get_gbs_measure(input: String) raises -> ThroughputMeasure:
#     return ThroughputMeasure(BenchMetric.bytes, input.byte_length())


fn run[func: fn (mut Bencher) raises capturing, name: String](mut m: Bench) raises:
    m.bench_function[func](BenchId(name))


@parameter
fn test_render_layout(mut b: Bencher) raises:
    @always_inline
    @parameter
    fn do() raises:
        _ = render_layout()

    b.iter[do]()


@parameter
fn test_basic_styling(mut b: Bencher) raises:
    @always_inline
    @parameter
    fn do() raises:
        _ = basic_styling()

    b.iter[do]()


@parameter
fn test_basic_comptime_styling(mut b: Bencher) raises:
    @always_inline
    @parameter
    fn do() raises:
        _ = basic_comptime_styling()

    b.iter[do]()


fn main() raises:
    var config = BenchConfig()
    config.verbose_timing = True
    config.tabular_view = True
    config.flush_denormals = True
    config.show_progress = True
    var bench = Bench(config)
    # test_render_layout()

    # var path = String(pathlib._dir_of_current_file()) + "/data/big.txt"
    # var data: String
    # with open(path, "r") as file:
    #     data = file.read()

    run[test_render_layout, "Layout"](bench)
    run[test_basic_styling, "BasicStyle"](bench)
    run[test_basic_comptime_styling, "CompTimeBasicStyle"](bench)

    # run[test_dedent, "Dedent"](bench_config, data)
    # run[test_margin, "Margin"](bench_config, data)
    # run[test_word_wrap, "WordWrap"](bench_config, data)
    # run[test_wrap, "Wrap"](bench_config, data)
    # run[test_truncate, "Truncate"](bench_config, data)
    # run[test_padding, "Padding"](bench_config, data)

    bench.dump_report()
    # report.print()


# fn main() raises:
#     var results = mog.Table.new().set_style(table_styling).set_headers(
#         "Name",
#         "Mean (ms)",
#         "Total (ms)",
#         "Iterations",
#         "Warmup Total",
#     )

#     var report = benchmark.run[render_layout](max_iters=10)
#     results = results.row(
#         "Render layout",
#         str(report.mean(benchmark.Unit.ms)),
#         str(report.duration(benchmark.Unit.ms)),
#         str(report.iters()),
#         str(report.warmup_duration / 1e6),
#     )

#     var bs_report = benchmark.run[basic_styling](max_iters=50)
#     results = results.row(
#         "Basic styling",
#         str(bs_report.mean(benchmark.Unit.ms)),
#         str(bs_report.duration(benchmark.Unit.ms)),
#         str(bs_report.iters()),
#         str(bs_report.warmup_duration / 1e6),
#     )

#     var bcs_report = benchmark.run[basic_comptime_styling](max_iters=50)
#     results = results.row(
#         "Basic comptime styling",
#         str(bcs_report.mean(benchmark.Unit.ms)),
#         str(bcs_report.duration(benchmark.Unit.ms)),
#         str(bcs_report.iters()),
#         str(bcs_report.warmup_duration / 1e6),
#     )

#     # var bs_big_report = benchmark.run[basic_styling_big_file](max_iters=10)
#     # results = results.row(
#     #     "Large file test",
#     #     str(bs_big_report.mean(benchmark.Unit.ms)),
#     #     str(bs_big_report.duration(benchmark.Unit.ms)),
#     #     str(bs_big_report.iters()),
#     #     str(bs_big_report.warmup_duration / 1e6),
#     #     str(bs_big_report.warmup_iters),
#     # )

#     print(results)
