
def python_script_impl(ctx: "context") -> ["provider"]:
    return [DefaultInfo(), RunInfo(ctx.attrs.file)]


python_script = rule(impl = python_script_impl, attrs = {
    "file": attrs.source(),
})
