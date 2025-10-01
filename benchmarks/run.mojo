import pathlib

import benchmark
from benchmark import Bench, BenchConfig, Bencher, BenchId, BenchMetric, ThroughputMeasure
from functions.basic_styling import basic_comptime_styling, basic_styling, basic_styling_big_file
from functions.layout import render_layout

import mog


fn get_gbs_measure(input: String) raises -> ThroughputMeasure:
    return ThroughputMeasure(BenchMetric.bytes, input.byte_length())


fn run[func: fn (mut Bencher) raises capturing, name: String](mut m: Bench) raises:
    m.bench_function[func](BenchId(name))


fn run[func: fn (mut Bencher, String) raises capturing, name: String](mut m: Bench, data: String) raises:
    m.bench_with_input[String, func](BenchId(name), data, get_gbs_measure(data))


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


@parameter
fn bench_get_width(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    fn do() raises:
        _ = mog.get_width(s)

    b.iter[do]()


fn main() raises:
    var config = BenchConfig()
    config.verbose_timing = True
    config.flush_denormals = True
    config.show_progress = True
    var bench = Bench(config^)

    # var sample_data = pathlib._dir_of_current_file() / pathlib.Path("data/big.txt")
    # var data: String
    # with open(sample_data, "r") as file:
    #     data = file.read()

    # run[bench_get_width, "GetWidth"](bench, data)

    run[test_render_layout, "Layout"](bench)
    run[test_basic_styling, "BasicStyle"](bench)
    run[test_basic_comptime_styling, "CompTimeBasicStyle"](bench)
    # run[bench_get_width, "GetWidth"](bench)

    bench.dump_report()


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
