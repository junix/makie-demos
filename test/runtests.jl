using MakieDemos
using Test
using JSON3
import CairoMakie

capture_error(f) = try
    f()
    nothing
catch e
    e
end

# Saves a synthetic PNG whose pixel buckets (count => color) tile the image in
# linear order, so validate_png counts can be predicted exactly.
function save_bucket_png(path, height, width, buckets)
    image = Matrix{CairoMakie.Colors.ARGB32}(undef, height, width)
    index = 0
    for (count, color) in buckets, _ in 1:count
        index += 1
        image[index] = color
    end
    @assert index == height * width
    CairoMakie.FileIO.save(path, image)
    return path
end

# The published catalog (catalog.json) is the source of truth for the demo set.
const EXPECTED_DEMO_NAMES = sort([
    "surface-terrain",
    "vector-field",
    "phase-dashboard",
    "uncertainty-forecast",
    "correlation-matrix",
    "parallel-coordinates",
    "sankey-energy",
    "volume-slices",
    "molecular-scene",
    "polar-climate",
    "gantt-system",
    "topology-graph",
])

@testset "DEMOS matches the published catalog" begin
    @test sort!(collect(keys(DEMOS))) == EXPECTED_DEMO_NAMES
    catalog = JSON3.read(read(joinpath(@__DIR__, "..", "catalog.json"), String))
    @test sort!([entry["id"] for entry in catalog]) == EXPECTED_DEMO_NAMES
end

@testset "transparent Makie renders" begin
    mktempdir() do output_dir
        paths = render_all(output_dir)
        names = EXPECTED_DEMO_NAMES
        @test length(paths) == length(DEMOS)
        @test paths == [joinpath(output_dir, "$name-transparent.png") for name in names]
        for (name, path) in zip(names, paths)
            @test isfile(path)
            stats = validate_png(path)
            @test stats.width == 1600
            @test stats.height == 1000
            @test stats.transparent_pixels > 280_000
            @test stats.visible_pixels > 10_000
            @test stats.colorful_pixels >= 3_000
            # alpha < 0.03 and alpha > 0.10 are disjoint buckets, colorful implies visible
            @test stats.transparent_pixels + stats.visible_pixels <= stats.width * stats.height
            @test stats.colorful_pixels <= stats.visible_pixels
            sidecar = replace(path, ".png" => ".json")
            @test isfile(sidecar)
            manifest = JSON3.read(read(sidecar, String))
            @test manifest["demo"] == name
            @test manifest["artifact"] == basename(path)
            @test manifest["background"] == "transparent"
            @test manifest["backend"] == "CairoMakie"
            @test manifest["data"] == "deterministic synthetic fixture"
            @test manifest["dimensions"]["width"] == stats.width
            @test manifest["dimensions"]["height"] == stats.height
            @test manifest["transparent_pixels"] == stats.transparent_pixels
            @test manifest["visible_pixels"] == stats.visible_pixels
            @test manifest["colorful_pixels"] == stats.colorful_pixels
            @test manifest["render_seconds"] >= 0
        end
    end
end

@testset "render_demo rejects unknown names without side effects" begin
    mktempdir() do output_dir
        target = joinpath(output_dir, "missing")
        err = capture_error(() -> render_demo("no-such-demo", target))
        @test err isa ErrorException
        @test occursin("unknown demo: no-such-demo", sprint(showerror, err))
        @test !isdir(target)
        @test readdir(output_dir) == []
    end
end

@testset "render_demo writes exactly the png and sidecar into a fresh nested dir" begin
    mktempdir() do output_dir
        target = joinpath(output_dir, "nested", "deep")
        path = render_demo("correlation-matrix", target)
        @test path == joinpath(target, "correlation-matrix-transparent.png")
        @test isdir(target)
        @test readdir(target) == ["correlation-matrix-transparent.json", "correlation-matrix-transparent.png"]
    end
end

@testset "render_demo re-render overwrites artifacts without leaving strays" begin
    mktempdir() do output_dir
        target = joinpath(output_dir, "out")
        first_path = render_demo("correlation-matrix", target)
        second_path = render_demo("correlation-matrix", target)
        @test second_path == first_path
        @test readdir(target) == ["correlation-matrix-transparent.json", "correlation-matrix-transparent.png"]
        manifest = JSON3.read(read(joinpath(target, "correlation-matrix-transparent.json"), String))
        @test manifest["demo"] == "correlation-matrix"
        @test manifest["artifact"] == "correlation-matrix-transparent.png"
        @test manifest["background"] == "transparent"
    end
end

@testset "validate_png rejects non-conforming images" begin
    FileIO = CairoMakie.FileIO
    Colors = CairoMakie.Colors
    mktempdir() do output_dir
        opaque = fill(Colors.ARGB32(0.9, 0.2, 0.4, 1.0), 60, 60)
        path = joinpath(output_dir, "opaque.png")
        FileIO.save(path, opaque)
        err = capture_error(() -> validate_png(path))
        @test err isa ErrorException
        @test occursin("lacks a transparent background", sprint(showerror, err))

        sparse = fill(Colors.ARGB32(0.0, 0.0, 0.0, 0.0), 100, 100)
        for i in 1:100
            sparse[i, i] = Colors.ARGB32(0.8, 0.3, 0.3, 0.5)
        end
        path = joinpath(output_dir, "sparse.png")
        FileIO.save(path, sparse)
        err = capture_error(() -> validate_png(path))
        @test err isa ErrorException
        @test occursin("has too little visible content", sprint(showerror, err))

        grayscale = fill(Colors.ARGB32(0.6, 0.6, 0.6, 1.0), 200, 200)
        grayscale[76:end, :] .= Colors.ARGB32(0.0, 0.0, 0.0, 0.0)
        path = joinpath(output_dir, "grayscale.png")
        FileIO.save(path, grayscale)
        err = capture_error(() -> validate_png(path))
        @test err isa ErrorException
        @test occursin("has too little colorful plot content", sprint(showerror, err))
    end
end

@testset "validate_png counts pixel buckets exactly" begin
    FileIO = CairoMakie.FileIO
    Colors = CairoMakie.Colors
    mktempdir() do output_dir
        # 200x250 = 50_000 pixels split into the four counting regimes:
        # alpha 0 (transparent), alpha 0.05 (inside the 0.03..0.10 gap, counted
        # nowhere), opaque gray (visible but not colorful), opaque saturated
        # (visible and colorful).
        height, width = 200, 250
        image = Matrix{Colors.ARGB32}(undef, height, width)
        for i in eachindex(image)
            if i <= 10_000
                image[i] = Colors.ARGB32(0.0, 0.0, 0.0, 0.0)
            elseif i <= 15_000
                image[i] = Colors.ARGB32(0.5, 0.5, 0.5, 0.05)
            elseif i <= 45_000
                image[i] = Colors.ARGB32(0.6, 0.6, 0.6, 1.0)
            else
                image[i] = Colors.ARGB32(0.9, 0.2, 0.4, 1.0)
            end
        end
        path = joinpath(output_dir, "buckets.png")
        FileIO.save(path, image)
        stats = validate_png(path)
        @test stats.width == width
        @test stats.height == height
        @test stats.transparent_pixels == 10_000
        @test stats.visible_pixels == 35_000
        @test stats.colorful_pixels == 5_000
    end
end

@testset "validate_png enforces thresholds at the exact boundary" begin
    Colors = CairoMakie.Colors
    mktempdir() do output_dir
        transparent_px = Colors.ARGB32(0.0, 0.0, 0.0, 0.0)
        gray_px = Colors.ARGB32(0.6, 0.6, 0.6, 1.0)
        accent_px = Colors.ARGB32(0.9, 0.2, 0.4, 1.0)
        # 200x250 = 50_000 pixels, and 50_000 * 0.18 == 9000.0 exactly, so
        # 9_000 transparent pixels is the smallest count passing guard one.
        @testset "transparent floor passes at exactly 18 percent" begin
            path = save_bucket_png(joinpath(output_dir, "edge-pass.png"), 200, 250, [
                9_000 => transparent_px,
                33_000 => gray_px,
                8_000 => accent_px,
            ])
            stats = validate_png(path)
            @test stats.transparent_pixels == 9_000
            @test stats.visible_pixels == 41_000
            @test stats.colorful_pixels == 8_000
        end
        @testset "transparent floor fails one pixel below 18 percent" begin
            path = save_bucket_png(joinpath(output_dir, "edge-fail.png"), 200, 250, [
                8_999 => transparent_px,
                33_001 => gray_px,
                8_000 => accent_px,
            ])
            # visible and colorful counts comfortably pass, so the message
            # proves the transparency guard is what rejected the image.
            err = capture_error(() -> validate_png(path))
            @test err isa ErrorException
            @test occursin("lacks a transparent background", sprint(showerror, err))
        end
        @testset "visible and colorful floors pass at exactly 10_000 and 3_000" begin
            path = save_bucket_png(joinpath(output_dir, "floor-pass.png"), 200, 250, [
                40_000 => transparent_px,
                7_000 => gray_px,
                3_000 => accent_px,
            ])
            stats = validate_png(path)
            @test stats.visible_pixels == 10_000
            @test stats.colorful_pixels == 3_000
        end
        @testset "visible floor fails one pixel below 10_000" begin
            path = save_bucket_png(joinpath(output_dir, "visible-fail.png"), 200, 250, [
                40_001 => transparent_px,
                7_000 => gray_px,
                2_999 => accent_px,
            ])
            err = capture_error(() -> validate_png(path))
            @test err isa ErrorException
            @test occursin("has too little visible content", sprint(showerror, err))
        end
        @testset "colorful floor fails one pixel below 3_000" begin
            path = save_bucket_png(joinpath(output_dir, "colorful-fail.png"), 200, 250, [
                40_000 => transparent_px,
                7_001 => gray_px,
                2_999 => accent_px,
            ])
            # visible == 10_000 exactly, so the colorful guard is what fires.
            err = capture_error(() -> validate_png(path))
            @test err isa ErrorException
            @test occursin("has too little colorful plot content", sprint(showerror, err))
        end
    end
end

@testset "validate_png counts mid-alpha saturated pixels as visible but not colorful" begin
    Colors = CairoMakie.Colors
    mktempdir() do output_dir
        # alpha 0.2 quantizes to exactly 51/255 in ARGB32: above the 0.10
        # visible bar, below the 0.25 colorful bar, so a fully saturated hue
        # at this alpha must land in the visible bucket only.
        path = save_bucket_png(joinpath(output_dir, "mid-alpha.png"), 200, 125, [
            10_000 => Colors.ARGB32(0.0, 0.0, 0.0, 0.0),
            10_000 => Colors.ARGB32(0.9, 0.2, 0.4, 0.2),
            5_000 => Colors.ARGB32(0.9, 0.2, 0.4, 1.0),
        ])
        stats = validate_png(path)
        @test stats.width == 125
        @test stats.height == 200
        @test stats.transparent_pixels == 10_000
        @test stats.visible_pixels == 15_000
        @test stats.colorful_pixels == 5_000
    end
end
