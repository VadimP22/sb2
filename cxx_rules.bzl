load(":types.bzl", "CxxLinkable", "CxxToolchain", "CxxConfig", "CdbFiles", "CxxIncludes")
load(":cxx_utils.bzl", "compile_cxx", "link_cxx", "reexport_linkables", "reexport_cdb_files", "prepare_includes")


def cxx_library_impl(ctx: "context") -> ["provider"]:
    new_objs = []
    new_cdbs = []
    
    inc_deps = []
    for dep in ctx.attrs.deps:
        inc_deps.append(dep[CxxIncludes])    
    all_includes = prepare_includes(deps = inc_deps, new_includes = ctx.attrs.includes)

    for src in ctx.attrs.sources:
        out = ctx.actions.declare_output(src.basename + ".linkable")
        cdb_out = ctx.actions.declare_output(src.basename + ".json")
        compile_cxx(
            ctx = ctx,
            toolchain = ctx.attrs.cxx_toolchain[CxxToolchain],
            config = ctx.attrs.cxx_config[CxxConfig],
            source = src,
            output = out,
            cdb_output = cdb_out,
            includes = all_includes,
        )
        new_objs.append(out)
        new_cdbs.append(cdb_out)


    lin_deps = []
    for dep in ctx.attrs.deps:
        lin_deps.append(dep[CxxLinkable])    
    linkables_provider = reexport_linkables(ctx = ctx, new_objs = new_objs, deps = lin_deps)

    cdb_deps = []
    for dep in ctx.attrs.deps:
        cdb_deps.append(dep[CdbFiles])
    cdb_files_provider = reexport_cdb_files(ctx = ctx, new_cdb_files = new_cdbs, deps = cdb_deps)
    
    return [
        cdb_files_provider,
        linkables_provider,
        CxxIncludes(list = all_includes),
        DefaultInfo(default_output = linkables_provider.objs[0]),
    ]


def cxx_executable_impl(ctx: "context") -> ["provider"]:
    out = ctx.actions.declare_output(
        ctx.attrs.name + "-" +
        ctx.attrs.cxx_config[CxxConfig].target
    )
    
    deps = []
    for dep in ctx.attrs.deps:
        deps.append(dep[CxxLinkable])

    link_cxx(
        ctx = ctx,
        toolchain = ctx.attrs.cxx_toolchain[CxxToolchain],
        config = ctx.attrs.cxx_config[CxxConfig],
        linkables = deps,
        output = out
    )

    return [
        DefaultInfo(default_output = out),
        RunInfo(out),
    ]


def cxx_cdb_impl(ctx: "context") -> ["provider"]:
    all_cdbs = []

    for dep in ctx.attrs.deps:
        for cdb in dep[CdbFiles].list:
            all_cdbs.append(cdb)

    out = ctx.actions.declare_output("compile_commands.json")
    ctx.actions.run([
        ctx.attrs.cxx_toolchain[CxxToolchain].mk_cdb[RunInfo],
        "merge",
        "--output",
        out.as_output(),
        all_cdbs,
    ], category = "merge_cdb", identifier = out.basename)
    
    return [
        DefaultInfo(default_output = out)
    ]



cxx_library = rule(impl = cxx_library_impl, attrs = {
    "sources": attrs.list(attrs.source()),
    "includes": attrs.list(attrs.source(allow_directory = True), default = []),
    "deps": attrs.list(attrs.dep(), default = []),
    "cxx_toolchain": attrs.toolchain_dep(default = "root//:cxx_toolchain"),
    "cxx_config": attrs.dep(default = "root//:cxx_config"),
})


cxx_executable = rule(impl = cxx_executable_impl, attrs = {
    "deps": attrs.list(attrs.dep()),
    "cxx_toolchain": attrs.toolchain_dep(default = "root//:cxx_toolchain"),
    "cxx_config": attrs.dep(default = "root//:cxx_config"),
})


cxx_cdb = rule(impl = cxx_cdb_impl, attrs = {
    "deps": attrs.list(attrs.dep(), default = []),
    "cxx_toolchain": attrs.toolchain_dep(default = "root//:cxx_toolchain"),
})
    
