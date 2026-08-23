module MakieDemos

using CairoMakie
using JSON3

export DEMOS, render_all, render_demo, validate_png

const INK = RGBf(0.08, 0.13, 0.23)
const MUTED = RGBf(0.32, 0.39, 0.49)
const ACCENT = RGBf(0.70, 0.25, 0.39)
const GRID = RGBAf(0.12, 0.22, 0.32, 0.13)

function apply_theme!()
    set_theme!(Theme(
        fontsize = 19,
        Figure = (backgroundcolor = :transparent,),
        Axis = (
            backgroundcolor = :transparent,
            xgridcolor = GRID,
            ygridcolor = GRID,
            spinecolor = RGBAf(INK.r, INK.g, INK.b, 0.45),
            xtickcolor = MUTED,
            ytickcolor = MUTED,
            xticklabelcolor = MUTED,
            yticklabelcolor = MUTED,
            xlabelcolor = INK,
            ylabelcolor = INK,
            titlesize = 22,
            titlecolor = INK,
        ),
        Colorbar = (
            ticklabelcolor = MUTED,
            labelcolor = INK,
            spinecolor = RGBAf(INK.r, INK.g, INK.b, 0.35),
        ),
    ))
end

function header!(fig, columns, kicker, title, subtitle)
    Label(
        fig[1, 1:columns],
        kicker;
        color = ACCENT,
        fontsize = 17,
        font = :bold,
        tellwidth = false,
        halign = :left,
    )
    Label(
        fig[2, 1:columns],
        title;
        color = INK,
        fontsize = 43,
        font = :bold,
        tellwidth = false,
        halign = :left,
    )
    Label(
        fig[3, 1:columns],
        subtitle;
        color = MUTED,
        fontsize = 18,
        tellwidth = false,
        halign = :left,
    )
    rowgap!(fig.layout, 1, 5)
    rowgap!(fig.layout, 2, 5)
end

function surface_terrain()
    fig = Figure(size = (1600, 1000), backgroundcolor = :transparent)
    header!(
        fig,
        2,
        "MAKIE · CAIROMAKIE · 3D SURFACE",
        "Folded terrain of interacting waves",
        "A transparent, publication-scale 3D surface with projected structure and a continuous legend.",
    )
    axis = Axis3(
        fig[4, 1];
        xlabel = "x coordinate",
        ylabel = "y coordinate",
        zlabel = "response",
        azimuth = 1.22pi,
        elevation = 0.23pi,
        aspect = (1.45, 1.0, 0.65),
        perspectiveness = 0.72,
        xypanelcolor = :transparent,
        xzpanelcolor = :transparent,
        yzpanelcolor = :transparent,
        xgridcolor = GRID,
        ygridcolor = GRID,
        zgridcolor = GRID,
    )
    xs = range(-4.2, 4.2, length = 190)
    ys = range(-3.2, 3.2, length = 155)
    z = [
        0.78 * sin(sqrt(x^2 + (1.25y)^2) * 2.1) * exp(-0.055 * (x^2 + y^2)) +
        0.32 * cos(1.6x - 0.8y) +
        0.12x for x in xs, y in ys
    ]
    surface = surface!(
        axis,
        xs,
        ys,
        z;
        color = z,
        colormap = :magma,
        shading = true,
        diffuse = Vec3f(0.9, 0.9, 0.9),
        specular = Vec3f(0.28, 0.28, 0.28),
        shininess = 22f0,
    )
    wireframe!(axis, xs, ys, z; color = RGBAf(1, 1, 1, 0.10), linewidth = 0.45)
    Colorbar(fig[4, 2], surface; label = "wave response", width = 24)
    colsize!(fig.layout, 1, Relative(0.91))
    return fig
end

function vector_field()
    fig = Figure(size = (1600, 1000), backgroundcolor = :transparent)
    header!(
        fig,
        2,
        "MAKIE · VECTOR FIELD",
        "Vortices meeting a directional current",
        "Arrow geometry, streamline hints, and scalar contours share one transparent analytical canvas.",
    )
    axis = Axis(
        fig[4, 1];
        xlabel = "horizontal state",
        ylabel = "vertical state",
        aspect = DataAspect(),
    )
    xs = collect(range(-4.5, 4.5, length = 27))
    ys = collect(range(-3.0, 3.0, length = 19))
    points = Point2f[]
    vectors = Vec2f[]
    speed = Float32[]
    for y in ys, x in xs
        u = -0.72y + 0.85 * sin(1.2x) + 0.20
        v = 0.58x + 0.66 * cos(1.35y) - 0.11x * y
        push!(points, Point2f(x, y))
        push!(vectors, Vec2f(u, v))
        push!(speed, sqrt(u^2 + v^2))
    end
    potential = [sin(1.15x) + cos(1.35y) + 0.13x * y for x in xs, y in ys]
    contour!(
        axis,
        xs,
        ys,
        potential;
        levels = 18,
        colormap = :ice,
        linewidth = 1.2,
        alpha = 0.28,
    )
    arrows = arrows2d!(
        axis,
        points,
        vectors;
        color = speed,
        colormap = :plasma,
        lengthscale = 0.115,
        shaftwidth = 2.8,
        tipwidth = 10,
        tiplength = 13,
    )
    Colorbar(fig[4, 2], arrows; label = "flow speed", width = 24)
    limits!(axis, -4.8, 4.8, -3.25, 3.25)
    colsize!(fig.layout, 1, Relative(0.91))
    return fig
end

function phase_dashboard()
    fig = Figure(size = (1600, 1000), backgroundcolor = :transparent)
    header!(
        fig,
        2,
        "MAKIE · MULTIPANEL ANALYSIS",
        "A dynamical system seen from four angles",
        "Time evolution, phase geometry, spectrum, and recurrence form one compositional figure.",
    )
    t = range(0, 42, length = 2400)
    x = @. sin(1.07t) + 0.42sin(2.31t + 0.4) + 0.08cos(7.2t)
    y = @. cos(0.91t + 0.8) + 0.37sin(2.08t) + 0.12cos(5.7t)

    time_axis = Axis(fig[4, 1:2]; xlabel = "time", ylabel = "state", title = "Evolution")
    lines!(time_axis, t, x; color = t, colormap = :viridis, linewidth = 3.2)
    lines!(time_axis, t, y; color = RGBAf(ACCENT.r, ACCENT.g, ACCENT.b, 0.72), linewidth = 1.8)

    phase_axis = Axis(
        fig[5, 1];
        xlabel = "state x",
        ylabel = "state y",
        title = "Phase portrait",
        aspect = DataAspect(),
    )
    lines!(phase_axis, x, y; color = t, colormap = :turbo, linewidth = 2.2)
    scatter!(phase_axis, x[1:95:end], y[1:95:end]; color = t[1:95:end], colormap = :turbo, markersize = 8)

    diagnostic = GridLayout(fig[5, 2])
    spectrum_axis = Axis(diagnostic[1, 1]; xlabel = "mode", ylabel = "energy", title = "Harmonic energy")
    modes = 1:24
    energy = @. exp(-0.115modes) * (0.48 + 0.52abs(sin(0.91modes)))
    barplot!(spectrum_axis, modes, energy; color = energy, colormap = :plasma, strokewidth = 0)

    recurrence_axis = Axis(
        diagnostic[2, 1];
        xlabel = "lag",
        ylabel = "window",
        title = "Recurrence contours",
    )
    recurrence = [
        sin(0.18i + 0.24j) * cos(0.04i * j) + 0.3sin(0.8i - 0.3j)
        for i in 1:74, j in 1:38
    ]
    contour!(recurrence_axis, recurrence; levels = 13, colormap = :magma, linewidth = 1.5)
    rowgap!(diagnostic, 18)
    return fig
end

const DEMOS = Dict(
    "surface-terrain" => surface_terrain,
    "vector-field" => vector_field,
    "phase-dashboard" => phase_dashboard,
)

function validate_png(path::AbstractString)
    image = CairoMakie.FileIO.load(path)
    colors = CairoMakie.Colors
    transparent = 0
    visible = 0
    colorful = 0
    for pixel in image
        a = colors.alpha(pixel)
        r = colors.red(pixel)
        g = colors.green(pixel)
        b = colors.blue(pixel)
        transparent += a < 0.03
        visible += a > 0.10
        colorful += a > 0.25 && (max(r, g, b) - min(r, g, b) > 0.10)
    end
    total = length(image)
    transparent >= total * 0.18 || error("$path lacks a transparent background")
    visible >= 10_000 || error("$path has too little visible content")
    colorful >= 3_000 || error("$path has too little colorful plot content")
    return (
        width = size(image, 2),
        height = size(image, 1),
        transparent_pixels = transparent,
        visible_pixels = visible,
        colorful_pixels = colorful,
    )
end

function render_demo(name::AbstractString, output_dir::AbstractString = "out")
    haskey(DEMOS, name) || error("unknown demo: $name")
    mkpath(output_dir)
    apply_theme!()
    figure = DEMOS[name]()
    path = joinpath(output_dir, "$name-transparent.png")
    started = time()
    save(path, figure; px_per_unit = 1)
    elapsed = time() - started
    stats = validate_png(path)
    manifest = Dict(
        "demo" => name,
        "artifact" => basename(path),
        "background" => "transparent",
        "dimensions" => Dict("width" => stats.width, "height" => stats.height),
        "transparent_pixels" => stats.transparent_pixels,
        "visible_pixels" => stats.visible_pixels,
        "colorful_pixels" => stats.colorful_pixels,
        "render_seconds" => round(elapsed; digits = 4),
        "backend" => "CairoMakie",
        "data" => "deterministic synthetic fixture",
    )
    open(replace(path, ".png" => ".json"), "w") do io
        JSON3.pretty(io, manifest)
        write(io, '\n')
    end
    return path
end

function render_all(output_dir::AbstractString = "out")
    return [render_demo(name, output_dir) for name in sort!(collect(keys(DEMOS)))]
end

end
