load(":types.bzl", "CxxLinkable", "CxxToolchain", "CxxConfig", "CdbFiles", "CxxIncludes")
load(":cxx_utils.bzl", "compile_cxx", "link_cxx", "reexport_linkables", "reexport_cdb_files", "prepare_includes")


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