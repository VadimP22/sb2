load(":cxx_library.bzl", "cxx_library_impl")
load(":cxx_executable.bzl", "cxx_executable_impl")
load(":cxx_cdb.bzl", "cxx_cdb_impl")


cxx_library = rule(impl = cxx_library_impl, attrs = {
    "sources": attrs.list(attrs.source()),
    "includes": attrs.list(attrs.source(allow_directory = True), default = []),
    "deps": attrs.list(attrs.dep(), default = []),
    "cxx_toolchain": attrs.toolchain_dep(default = "root//:cxx_toolchain"),
    "cxx_config": attrs.dep(default = "root//:cxx_config"),
})


cxx_executable = rule(impl = cxx_executable_impl, attrs = {
    "sources": attrs.list(attrs.source(), default = []),
    "includes": attrs.list(attrs.source(allow_directory = True), default = []),
    "deps": attrs.list(attrs.dep(), default = []),
    "cxx_toolchain": attrs.toolchain_dep(default = "root//:cxx_toolchain"),
    "cxx_config": attrs.dep(default = "root//:cxx_config"),
})


cxx_cdb = rule(impl = cxx_cdb_impl, attrs = {
    "deps": attrs.list(attrs.dep(), default = []),
    "cxx_toolchain": attrs.toolchain_dep(default = "root//:cxx_toolchain"),
})    
