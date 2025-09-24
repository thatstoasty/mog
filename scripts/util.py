import tomllib
import os
import subprocess
import shutil
from typing import Any
from pathlib import Path

import typer


app = typer.Typer()

TEMP_DIR = Path(os.path.expandvars("$HOME/tmp"))
PIXI_TOML_PATH = Path("pixi.toml")
RECIPE_PATH = Path("recipe.yaml")
CONDA_BUILD_PATH = Path(os.environ.get("CONDA_BLD_PATH", os.getcwd()))
"""If `CONDA_BLD_PATH` is set, then publish from there. Otherwise, publish from the current directory."""

def load_project_config() -> dict[str, Any]:
    """Loads the project configuration from the pixi.toml file."""
    with PIXI_TOML_PATH.open("rb") as f:
        return tomllib.load(f)

PROJECT_CONFIG = load_project_config()


class TemporaryBuildDirectory:
    """Context manager to create a temporary build directory."""
    def __enter__(self) -> Path:
        TEMP_DIR.mkdir(parents=True, exist_ok=True)
        package = PROJECT_CONFIG["package"]["name"]
        subprocess.run(
            ["mojo", "package", f"{package}", "-o", f"{TEMP_DIR}/{package}.mojopkg"],
            check=True,
        )
        return TEMP_DIR

    def __exit__(self, exc_type: Any, exc_value: Any, traceback: Any) -> None:
        if TEMP_DIR.exists():
            shutil.rmtree(TEMP_DIR)
            print("Temporary build directory removed.")


def format_dependency(name: str, version: str) -> str:
    """Converts the list of dependencies from the pixi.toml into a list of strings for the recipe."""
    start = 0
    operator = "=="
    if version[0] in {"<", ">"}:
        if version[1] != "=":
            operator = version[0]
            start = 1
        else:
            operator = version[:2]
            start = 2

    return f"{name} {operator} {version[start:]}"


def remove_temp_directory() -> None:
    """Removes the temporary directory used for building the package."""
    if TEMP_DIR.exists():
        print("Removing temp directory.")
        shutil.rmtree(TEMP_DIR)


def prepare_temp_directory() -> None:
    """Creates the temporary directory used for building the package. Adds the compiled mojo package to the directory."""
    remove_temp_directory()
    TEMP_DIR.mkdir()
    package = PROJECT_CONFIG["package"]["name"]
    subprocess.run(
        ["mojo", "package", f"{package}", "-o", f"{TEMP_DIR}/{package}.mojopkg"],
        check=True,
    )


@app.command()
def run_examples(path: str | None = None) -> None:
    """Executes the examples for the package."""
    EXAMPLE_DIR = Path("examples")
    if not EXAMPLE_DIR.exists():
        print(f"Path does not exist: {EXAMPLE_DIR}.")
        return

    print("Building package and copying examples.")
    with TemporaryBuildDirectory() as temp_directory:
        shutil.copytree(EXAMPLE_DIR, temp_directory, dirs_exist_ok=True)
        example_files = EXAMPLE_DIR.glob("*.mojo")
        if path:
            example_files = EXAMPLE_DIR.glob(path)

        for file in example_files:
            print(f"\nRunning example: {file}")
            name, _ = file.name.split(".", 1)
            shutil.copyfile(file, temp_directory / file.name)
            subprocess.run(["mojo", "build", temp_directory / file.name, "-o", temp_directory / name], check=True)
            subprocess.run([temp_directory / name], check=True)


@app.command()
def run_benchmarks(path: str | None = None) -> None:
    BENCHMARK_DIR = Path("benchmarks")
    if not BENCHMARK_DIR.exists():
        print(f"Path does not exist: {BENCHMARK_DIR}.")
        return

    print("Building package and copying benchmarks.")
    with TemporaryBuildDirectory() as temp_directory:
        shutil.copytree(BENCHMARK_DIR, temp_directory, dirs_exist_ok=True)
        benchmark_files = BENCHMARK_DIR.glob("*.mojo")
        if path:
            benchmark_files = BENCHMARK_DIR.glob(path)

        for file in benchmark_files:
            print(f"\nRunning benchmark: {file}")
            name, _ = file.name.split(".", 1)
            shutil.copyfile(file, temp_directory / file.name)
            subprocess.run(["mojo", "build", temp_directory / file.name, "-o", temp_directory / name], check=True)
            subprocess.run([temp_directory / name], check=True)


if __name__ == "__main__":
    app()
