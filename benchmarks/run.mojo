from std import pathlib, benchmark
from std.benchmark import Bench, BenchConfig, Bencher, BenchId, BenchMetric, ThroughputMeasure
from functions.basic_styling import basic_comptime_styling, basic_styling, basic_styling_big_file
from functions.layout import render_layout

import mog


def get_gbs_measure(input: String) raises -> ThroughputMeasure:
    return ThroughputMeasure(BenchMetric.bytes, input.byte_length())


def run[func: def (mut Bencher) raises capturing, name: String](mut m: Bench) raises:
    m.bench_function[func](BenchId(name))


def run[func: def (mut Bencher, String) raises capturing, name: String](mut m: Bench, data: String) raises:
    m.bench_with_input[String, func](BenchId(name), data, [get_gbs_measure(data)])


@parameter
def test_render_layout(mut b: Bencher) raises:
    @always_inline
    @parameter
    def do() raises:
        _ = render_layout()

    b.iter[do]()


@parameter
def test_basic_styling(mut b: Bencher) raises:
    @always_inline
    @parameter
    def do() raises:
        _ = basic_styling()

    b.iter[do]()


@parameter
def test_basic_comptime_styling(mut b: Bencher) raises:
    @always_inline
    @parameter
    def do() raises:
        _ = basic_comptime_styling()

    b.iter[do]()


@parameter
def bench_get_width(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    def do() raises:
        _ = mog.get_width(s)

    b.iter[do]()


def main() raises:
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
