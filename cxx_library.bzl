load(":types.bzl", "CxxLinkable", "CxxToolchain", "CxxConfig", "CdbFiles", "CxxIncludes")
load(":cxx_utils.bzl", "compile_cxx", "link_cxx", "reexport_linkables", "reexport_cdb_files", "prepare_includes", "run_tests")


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


    test_deps = []
    for dep in ctx.attrs.test_deps:
        test_deps.append(dep[RunInfo])
    run_tests(ctx = ctx, tests = test_deps)
    
    return [
        cdb_files_provider,
        linkables_provider,
        CxxIncludes(list = all_includes),
        DefaultInfo(default_output = linkables_provider.objs[0]),
    ]