from std import pathlib, time, benchmark
from std.benchmark import Bench, BenchConfig, Bencher, BenchId, BenchMetric, ThroughputMeasure
from std.python import Python, PythonObject
from std.sys import argv
from std.pathlib import Path

import mog

from functions.basic_styling import basic_comptime_styling, basic_styling, basic_styling_big_file
from functions.layout import render_layout
from functions.simple_table import render_table

comptime BenchResults = Dict[String, Float64]


def run_benchmarks(mut m: Bench) raises:
    var args = argv()
    var print_relative = False
    var overwrite = False

    for i in range(len(args)):
        if args[i] == "--print-relative":
            print_relative = True
        if args[i] == "--overwrite":
            overwrite = True

    var report_str: String
    if print_relative or overwrite:
        report_str = capture_report(m)
        print(report_str)
    else:
        m.dump_report()
        return

    var new_results = parse_report(report_str)

    if print_relative:
        var old_content: String = ""
        try:
            with open("bench_result.txt", "r") as f:
                old_content = f.read()
        except:
            print("Could not read bench_result.txt for comparison")
        var old_results = parse_report(old_content)
        print_relative_performance(old_results^, new_results^)

    if overwrite:
        write_report(report_str)


def capture_report(mut m: Bench) raises -> String:
    var os = Python.import_module("os")
    var sys_py = Python.import_module("sys")
    var io = Python.import_module("io")

    # Create pipe
    var r_w = os.pipe()  # Returns (r, w) tuple
    var r = r_w[0]
    var w = r_w[1]

    var stdout_fd = sys_py.stdout.fileno()
    var saved_stdout = os.dup(stdout_fd)

    # Redirect stdout to pipe
    _ = os.dup2(w, stdout_fd)

    m.dump_report()

    # Flush and restore
    _ = sys_py.stdout.flush()
    _ = os.dup2(saved_stdout, stdout_fd)
    _ = os.close(w)

    # Read from pipe
    var file_obj = os.fdopen(r)
    var content = file_obj.read()

    return String(content)


def parse_report(report: String) raises -> BenchResults:
    var lines = report.split("\n")
    var results = BenchResults()

    # Find header index
    var header_idx = -1
    var col_idx = -1
    for i in range(len(lines)):
        if "DataMovement (GB/s)" in lines[i]:
            header_idx = i
            var parts = lines[i].split("|")
            for j in range(len(parts)):
                if "DataMovement (GB/s)" in parts[j]:
                    col_idx = j
            break

    if header_idx == -1 or col_idx == -1:
        return results^

    for i in range(header_idx + 1, len(lines)):
        var line = lines[i]
        if not line or line.strip().startswith("-"):
            continue
        var parts = line.split("|")
        if len(parts) > col_idx:
            var name = parts[1].strip()
            var val_str = parts[col_idx].strip()
            try:
                # Try direct Float64 parsing from string
                var val_flt = Float64(val_str)
                results[String(name)] = val_flt
            except:
                pass

    return results^


def fixed_width(value: String, length: Int) -> String:
    """Returns the first `length` bytes of `value`, or all of it when it is shorter.

    The numbers below are trimmed to fixed widths to keep the table columns aligned.
    Slicing blindly overruns short values: an unchanged benchmark formats its diff as
    `0.0` and its speedup as `1.0`, both 3 bytes long.

    Args:
        value: The formatted number to trim.
        length: The maximum number of bytes to keep.

    Returns:
        The trimmed value.
    """
    if value.byte_length() <= length:
        return value.copy()

    return String(value[byte=0:length])


def print_relative_performance(
    var old_results: BenchResults,
    var new_results: BenchResults,
) raises:
    print("")
    print("Relative Performance (GB/s vs bench_result.txt)")
    print("---------------------------------------------------------------------------------------------------------")
    print("| Benchmark Name                                | Old (GB/s) | New (GB/s) | Diff       | Speedup     |")
    print("|-----------------------------------------------|------------|------------|------------|-------------|")

    for item in new_results.items():
        var name = item.key
        var new_val = item.value

        var name_pad = name
        while name_pad.byte_length() < 45:
            name_pad = name_pad + " "

        if name in old_results:
            var old_val = old_results[name]
            var diff_pct = (new_val - old_val) / old_val * 100.0
            var speedup = new_val / old_val

            var sign = "+" if diff_pct >= 0 else ""
            var diff_str = String(sign + fixed_width(String(diff_pct), 5) + "%")
            var speedup_str = String(fixed_width(String(speedup), 4) + "x")
            var old_str = fixed_width(String(old_val), 6)
            var new_str = fixed_width(String(new_val), 6)

            # Pad output manually (inefficient but works without formatting lib)
            var pad_len = 10
            while old_str.byte_length() < pad_len:
                old_str = old_str + " "
            while new_str.byte_length() < pad_len:
                new_str = new_str + " "
            while diff_str.byte_length() < pad_len:
                diff_str = diff_str + " "
            while speedup_str.byte_length() < 11:
                speedup_str = speedup_str + " "

            # Color the diff/speedup columns. Apply after padding so the visual
            # column widths stay aligned (ANSI escapes are zero-width).
            # Threshold: ±1% to avoid coloring obvious noise.
            comptime ANSI_GREEN = "\x1b[32m"
            comptime ANSI_RED = "\x1b[31m"
            comptime ANSI_RESET = "\x1b[0m"
            if diff_pct > 1.0:
                diff_str = ANSI_GREEN + diff_str + ANSI_RESET
                speedup_str = ANSI_GREEN + speedup_str + ANSI_RESET
            elif diff_pct < -1.0:
                diff_str = ANSI_RED + diff_str + ANSI_RESET
                speedup_str = ANSI_RED + speedup_str + ANSI_RESET

            print("| " + name_pad + " | " + old_str + " | " + new_str + " | " + diff_str + " | " + speedup_str + " |")
        else:
            # Pad to the same column width as the branch above, so a benchmark with no
            # baseline still lines up with the rest of the table.
            var new_str = fixed_width(String(new_val), 6)
            while new_str.byte_length() < 10:
                new_str = new_str + " "

            print(
                "| " + name_pad + " | N/A        | " + new_str + " | N/A        | N/A         |"
            )

    print("---------------------------------------------------------------------------------------------------------")
    print("")


def write_report(report: String) raises:
    var header = String("Run on unknown system")
    try:
        var platform = Python.import_module("platform")
        var system = String(platform.system())

        var cpu_info = String("")
        if system == "Darwin":
            var subprocess = Python.import_module("subprocess")
            # Try to get MacOS CPU brand string
            try:
                var cmd = Python.evaluate("['sysctl', '-n', 'machdep.cpu.brand_string']")
                var res = subprocess.check_output(cmd).decode("utf-8").strip()
                cpu_info = String(res)

                var cmd_cores = Python.evaluate("['sysctl', '-n', 'hw.physicalcpu']")
                var cores = subprocess.check_output(cmd_cores).decode("utf-8").strip()

                var cmd_mem = Python.evaluate("['sysctl', '-n', 'hw.memsize']")
                var mem_bytes = subprocess.check_output(cmd_mem).decode("utf-8").strip()
                # Use Python to format bytes to GB
                var mem_gb_py = Python.evaluate("'{:.2f}'.format(" + String(mem_bytes) + "/(1024**3))")
                var mem_gb = String(mem_gb_py)

                cpu_info = cpu_info + "\nCores: " + String(cores) + "\nMemory: " + mem_gb + " GB"
            except:
                pass

        if cpu_info.byte_length() == 0:
            cpu_info = String(platform.machine()) + " " + String(platform.processor())

        header = "Run on " + String(system) + " " + String(platform.release()) + "\nCPU: " + cpu_info
    except:
        pass

    var content = header + "\n\n" + report
    with open("bench_result.txt", "w") as f:
        f.write(content)
    print("Updated bench_result.txt")


def get_gbs_measure(input: String) raises -> ThroughputMeasure:
    return ThroughputMeasure(BenchMetric.bytes, input.byte_length())


def run[func: def(mut Bencher, String) raises capturing, name: String](mut m: Bench, data: String) raises:
    m.bench_with_input[String, func](BenchId(name), data, [get_gbs_measure(data)])


def run[func: def(mut Bencher) raises capturing, name: String](mut m: Bench) raises:
    m.bench_function[func](BenchId(name))


@parameter
def test_render_layout(mut b: Bencher) raises:
    @always_inline
    @parameter
    def do() raises:
        _ = render_layout()

    b.iter[do]()


@parameter
def test_render_table(mut b: Bencher) raises:
    @always_inline
    @parameter
    def do() raises:
        _ = render_table()

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

    run[test_render_layout, "Layout"](bench)
    run[test_basic_styling, "BasicStyle"](bench)
    run[test_basic_comptime_styling, "CompTimeBasicStyle"](bench)
    run[test_render_table, "RenderTable"](bench)

    comptime data = "🍥🍥🍥🍥🍥🍥"
    run[bench_get_width, "GetWidth"](bench, data)

    run_benchmarks(bench)
