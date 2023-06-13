load(":types.bzl", "CxxLinkable", "CxxToolchain", "CxxConfig", "CdbFiles")

def compile_cxx(
    ctx: "context",
    toolchain: CxxToolchain.type,
    config: CxxConfig.type,
    source: "artifact",
    output: "artifact",
    cdb_output:"artifact",
    includes: ["artifact"]):
    cxx = toolchain.compiler
    includes_args = []

    if len(includes) > 0:
        includes_args.append(config.compiler_includes_flag)
        for inc in includes:
            includes_args.append(inc)
        
    cxx_args = [
        config.compiler_base_flags,
        config.compiler_flags,
        source,
        includes_args,
        config.compiler_output_flag
    ]
        
    ctx.actions.run([
        cxx,
        cxx_args,
        output.as_output()
    ], category = "compile_cxx", identifier = source.short_path)

    ctx.actions.run([
        toolchain.mk_cdb[RunInfo],
        "gen",
        "--output",
        cdb_output.as_output(),
        source,
        "",
        "--",
        cxx,
        cxx_args,
        output
    ], category = "gen_cdb", identifier = source.short_path)



def link_cxx(
    ctx: "context",
    toolchain: CxxToolchain.type,
    config: CxxConfig.type,
    linkables: [CxxLinkable.type],
    output: "artifact",):
    all_objs = []

    for l in linkables:
        for obj in l.objs:
            all_objs.append(obj)

    ctx.actions.run([
        toolchain.linker,
        all_objs,
        "-o",
        output.as_output(),
    ], category = "link_cxx", identifier = ctx.attrs.name)


def reexport_linkables(ctx: "context", new_objs: ["artifact"], new_includes: ["artifact"], deps: [CxxLinkable.type]) -> "provider":
    all_objs = new_objs
    all_includes = new_includes

    for dep in deps:
        for obj in dep.objs:
            all_objs.append(obj)

        for include in dep.includes:
            all_includes.append(include)
            
    return CxxLinkable(objs = all_objs, includes = all_includes)


def reexport_cdb_files(ctx: "context", new_cdb_files: ["artifact"]) -> "provider":
    all_cdb_files = new_cdb_files
    for dep in ctx.attrs.deps:
        for cdb in dep[CdbFiles].list:
            all_cdb_files.append(cdb)

    return CdbFiles(list = all_cdb_files)


def prepare_includes(deps: [CxxLinkable.type], new_includes: ["artifact"]) -> ["artifact"]:
    all_includes = new_includes
    for dep in deps:
        for inc in dep.includes:
            all_includes.append(inc)

    return all_includes


def cxx_library_impl(ctx: "context") -> ["provider"]:
    new_objs = []
    new_cdbs = []
    
    deps = []
    for dep in ctx.attrs.deps:
        deps.append(dep[CxxLinkable])    

    all_includes = prepare_includes(deps = deps, new_includes = ctx.attrs.includes)

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

    linkables_provider = reexport_linkables(ctx = ctx, new_objs = new_objs,
        new_includes = ctx.attrs.includes, deps = deps)

    cdb_files_provider = reexport_cdb_files(ctx = ctx, new_cdb_files = new_cdbs)
    
    return [
        cdb_files_provider,
        linkables_provider,
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
    
