load(":toolchain.bzl", "cxx_config", "cxx_toolchain")
cxx_config = cxx_config
cxx_toolchain = cxx_toolchain

load(":cxx_rules.bzl", "cxx_library", "cxx_executable", "cxx_cdb")
cxx_sources = cxx_library
cxx_executable = cxx_executable
cxx_compile_commands = cxx_cdb

load("tools/python_script.bzl", "python_script")


def cxx_native():
    cxx_config(name = "cxx_config")
    cxx_toolchain(name = "cxx_toolchain")


def cxx_wasm():
    cxx_config(name = "cxx_config")
    cxx_toolchain(
        name = "cxx_toolchain",
        compiler = "emcc",
        linker = "emcc",
    )
    