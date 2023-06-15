load(":types.bzl", "CxxLinkable", "CxxToolchain", "CxxConfig", "CdbFiles", "CxxIncludes")
load(":cxx_utils.bzl", "compile_cxx", "link_cxx", "reexport_linkables", "reexport_cdb_files", "prepare_includes")


def cxx_executable_impl(ctx: "context") -> ["provider"]:
    out_executable = ctx.actions.declare_output(ctx.attrs.name)

    all_includes = ctx.attrs.includes
    for dep in ctx.attrs.deps:
        for inc in dep[CxxIncludes].list:
            all_includes.append(inc)

    linkables = []
    new_cdb_files = []
    for file in ctx.attrs.sources:
        out_linkable = ctx.actions.declare_output(file.basename + ".o")
        cdb_out = ctx.actions.declare_output(file.basename + ".json")
        compile_cxx(
            ctx = ctx,
            toolchain = ctx.attrs.cxx_toolchain[CxxToolchain],
            config = ctx.attrs.cxx_config[CxxConfig],
            source = file,
            output = out_linkable,
            cdb_output = cdb_out,
            includes = all_includes
            
        )
        new_cdb_files.append(cdb_out)
        linkables.append(out_linkable)
    
    lin_deps = []
    for dep in ctx.attrs.deps:
        lin_deps.append(dep[CxxLinkable])

    lin_deps.append(CxxLinkable(objs = linkables))
    print(lin_deps)

    link_cxx(
        ctx = ctx,
        toolchain = ctx.attrs.cxx_toolchain[CxxToolchain],
        config = ctx.attrs.cxx_config[CxxConfig],
        linkables = lin_deps,
        output = out_executable,
    )

    cdb_deps = []
    for dep in ctx.attrs.deps:
        cdb_deps.append(dep[CdbFiles])

    cdb_files_provider = reexport_cdb_files(
        ctx = ctx,
        new_cdb_files = new_cdb_files,
        deps = cdb_deps,
    )

    return [
        DefaultInfo(default_output = out_executable),
        RunInfo(out_executable),
        cdb_files_provider,
    ]