using MakieDemos
using Test

@testset "transparent Makie renders" begin
    mktempdir() do output_dir
        paths = render_all(output_dir)
        @test length(paths) >= 12
        for path in paths
            stats = validate_png(path)
            @test stats.width == 1600
            @test stats.height == 1000
            @test stats.transparent_pixels > 280_000
            @test stats.visible_pixels > 10_000
            @test isfile(replace(path, ".png" => ".json"))
        end
    end
end
