load(":types.bzl", "CxxLinkable", "CxxToolchain", "CxxConfig", "CdbFiles", "CxxIncludes")

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
        # includes_args.append(config.compiler_includes_flag)
        for inc in includes:
            includes_args.append(config.compiler_includes_flag)
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
        output.short_path
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


def reexport_linkables(ctx: "context", new_objs: ["artifact"], deps: [CxxLinkable.type]) -> "provider":
    all_objs = new_objs

    for dep in deps:
        for obj in dep.objs:
            all_objs.append(obj)

            
    return CxxLinkable(objs = all_objs)


def reexport_cdb_files(ctx: "context", new_cdb_files: ["artifact"], deps: [CdbFiles.type]) -> "provider":
    all_cdb_files = new_cdb_files
    for dep in deps:
        for cdb in dep.list:
            all_cdb_files.append(cdb)

    return CdbFiles(list = all_cdb_files)


def prepare_includes(deps: [CxxIncludes.type], new_includes: ["artifact"]) -> ["artifact"]:
    all_includes = new_includes
    for dep in deps:
        for inc in dep.list:
            all_includes.append(inc)

    return all_includes

