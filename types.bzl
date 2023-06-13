# C++
CxxLinkable = provider(fields = [
    "objs",
    "includes",
])

CxxToolchain = provider(fields = [
    "compiler",
    "linker",
    "mk_cdb",
])

CxxConfig = provider(fields = [
    "target",
    "mode",
    "compiler_debug_flags",
    "compiler_release_flags",
    "compiler_base_flags",
    "compiler_flags",
    "compiler_output_flag",
    "compiler_includes_flag",
])

CdbFiles = provider(fields = [
    "list",
])
