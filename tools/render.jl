using MakieDemos

output_dir = isempty(ARGS) ? "out" : ARGS[1]
for path in render_all(output_dir)
    stats = validate_png(path)
    println(
        "rendered $path ($(stats.width)x$(stats.height), ",
        "$(stats.transparent_pixels) transparent pixels)",
    )
end
