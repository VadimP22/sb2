load(":types.bzl", "CxxToolchain", "CxxConfig")

def cxx_config_impl(ctx: "context") -> ["provider"]:
    return [
        DefaultInfo(),
        CxxConfig(
            target = ctx.attrs.target,
            mode = ctx.attrs.mode,
            compiler_debug_flags = ctx.attrs.compiler_debug_flags,
            compiler_release_flags = ctx.attrs.compiler_release_flags,
            compiler_base_flags = ctx.attrs.compiler_base_flags,
            compiler_flags = ctx.attrs.compiler_flags,
            compiler_output_flag = ctx.attrs.compiler_output_flag,
            compiler_includes_flag = ctx.attrs.compiler_includes_flag,
        ),
    ]

cxx_config = rule(impl = cxx_config_impl,  attrs = {
    "target": attrs.string(default = "native"),
    "mode": attrs.string(default = "debug"),
    "compiler_debug_flags": attrs.list(attrs.string(), default = []),
    "compiler_release_flags": attrs.list(attrs.string(), default = ["-O3"]),
    "compiler_base_flags": attrs.list(attrs.string(), default = []),
    "compiler_flags": attrs.list(attrs.string(), default = ["-c"]),
    "compiler_output_flag": attrs.string(default = "-o"),
    "compiler_includes_flag": attrs.string(default = "-I"),
}, is_configuration_rule = True)


def cxx_toolchain_impl(ctx: "context") -> ["provider"]:
    return [
        DefaultInfo(),
        CxxToolchain(
            compiler = ctx.attrs.compiler,
            linker = ctx.attrs.linker,
            mk_cdb = ctx.attrs.mk_cdb,
        )
    ]

cxx_toolchain = rule(impl = cxx_toolchain_impl, attrs = {
    "compiler": attrs.string(default = "g++"),
    "linker": attrs.string(default = "g++"),
    "mk_cdb": attrs.exec_dep(default = "prelude//tools:mk_cdb"),
}, is_toolchain_rule = True)
