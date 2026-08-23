module MakieDemos

using CairoMakie
using JSON3
using Statistics

export DEMOS, render_all, render_demo, validate_png

const INK = RGBf(0.08, 0.13, 0.23)
const MUTED = RGBf(0.32, 0.39, 0.49)
const ACCENT = RGBf(0.70, 0.25, 0.39)
const GRID = RGBAf(0.12, 0.22, 0.32, 0.13)
const PALETTE = (RGBf(0.33, 0.84, 0.78), RGBf(0.48, 0.61, 1.0), RGBf(1.0, 0.44, 0.58), RGBf(1.0, 0.82, 0.4))
with_alpha(color, alpha) = RGBAf(color.r, color.g, color.b, alpha)

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

function uncertainty_forecast()
    fig=Figure(size=(1600,1000),backgroundcolor=:transparent);header!(fig,2,"MAKIE · ENSEMBLE FORECAST","Forecast fan with calibrated uncertainty","Two hundred deterministic trajectories, percentile bands, observations, and residual diagnostics.")
    ax=Axis(fig[4,1:2];xlabel="forecast horizon",ylabel="response",title="Ensemble and credible intervals");t=range(0,24,length=260);members=[@. 0.08t+sin(t/2.8)+0.06m*cos(t*(0.7+0.002m))+(m-100)*0.006*(t/24)^1.4 for m in 1:200];mat=hcat(members...);lo=[quantile(mat[i,:],.1) for i in axes(mat,1)];hi=[quantile(mat[i,:],.9) for i in axes(mat,1)];mid=[quantile(mat[i,:],.5) for i in axes(mat,1)];band!(ax,t,lo,hi;color=RGBAf(.31,.62,.74,.25));for m in 1:8:200 lines!(ax,t,members[m];color=RGBAf(.28,.42,.65,.12),linewidth=1) end;lines!(ax,t,mid;color=ACCENT,linewidth=4)
    err=Axis(fig[5,1];xlabel="horizon",ylabel="spread",title="80% interval width");lines!(err,t,hi.-lo;color=:darkorange,linewidth=3);cov=Axis(fig[5,2];xlabel="horizon",ylabel="coverage",title="Rolling calibration");coverage=@. .82+.08sin(t*.45)-.04cos(t*.12);lines!(cov,t,coverage;color=:teal,linewidth=3);hlines!(cov,[.8];color=RGBAf(INK.r,INK.g,INK.b,.3),linestyle=:dash);fig
end

function correlation_matrix()
    fig=Figure(size=(1600,1000),backgroundcolor=:transparent);header!(fig,2,"MAKIE · MATRIX ANALYSIS","Correlation and dependency matrix","A signed 14×14 system matrix combines magnitude, direction, clusters, and readable labels.")
    names=["load","latency","errors","queue","cache","cpu","memory","disk","network","users","jobs","retries","cost","slo"];n=length(names);matrix=[i==j ? 1.0 : clamp(.72sin(i*.7+j*.31)+.25cos(i*j*.11),-1,1) for i in 1:n,j in 1:n];ax=Axis(fig[4,1];xticks=(1:n,names),yticks=(1:n,names),xticklabelrotation=pi/3,aspect=DataAspect(),title="Signed correlation");hm=heatmap!(ax,matrix;colormap=:balance,colorrange=(-1,1));for i in 1:n,j in 1:n text!(ax,string(round(matrix[i,j];digits=1));position=(i,j),align=(:center,:center),fontsize=11,color=abs(matrix[i,j])>.55 ? :white : INK) end;Colorbar(fig[4,2],hm;label="correlation",width=26);colsize!(fig.layout,1,Relative(.91));fig
end

function parallel_coordinates()
    fig=Figure(size=(1600,1000),backgroundcolor=:transparent);header!(fig,1,"MAKIE · MULTIVARIATE PROFILES","Parallel-coordinate expedition profiles","Every expedition remains visible while five dimensions and four mission classes preserve context.")
    ax=Axis(fig[4,1];limits=(.6,5.4,0,1),xticks=(1:5,["elevation","temperature","humidity","wind","visibility"]),ylabel="normalized value",title="84 field campaigns");for i in 1:84 vals=[mod(i*17+j*29+j*i*3,97)/96 for j in 1:5];lines!(ax,1:5,vals;color=with_alpha(PALETTE[mod1(i,4)],0.34),linewidth=1.8);scatter!(ax,1:5,vals;color=[mod1(i,4) for _ in 1:5],colormap=collect(PALETTE),markersize=5) end;for x in 1:5 vlines!(ax,[x];color=RGBAf(INK.r,INK.g,INK.b,.28)) end;fig
end

function sankey_energy()
    fig=Figure(size=(1600,1000),backgroundcolor=:transparent);header!(fig,1,"MAKIE · FLOW DIAGRAM","Energy conversion Sankey","Source, storage, demand, and loss channels are encoded as proportionally thick ribbons.")
    ax=Axis(fig[4,1];limits=(0,10,0,10),aspect=DataAspect(),title="Renewable system flows");hidedecorations!(ax);hidespines!(ax);nodes=[(1,8,"Wind",2.2,PALETTE[1]),(1,5,"Solar",2.7,PALETTE[4]),(1,2,"Hydro",1.7,PALETTE[2]),(4.5,6.5,"Grid",3.0,PALETTE[2]),(4.5,2.7,"Storage",2.0,PALETTE[3]),(8,8,"Homes",1.8,PALETTE[1]),(8,5,"Industry",2.4,PALETTE[3]),(8,2,"Mobility",1.6,PALETTE[4])];for (x,y,n,h,c) in nodes poly!(ax,Rect2f(x-.35,y-h/2,.7,h);color=with_alpha(c,.65),strokecolor=c,strokewidth=2);text!(ax,n;position=(x,y),align=(:center,:center),color=INK,fontsize=16) end
    flows=[(1.35,8,4.15,7.4,.8,PALETTE[1]),(1.35,5,4.15,6.5,1.0,PALETTE[4]),(1.35,2,4.15,5.7,.7,PALETTE[2]),(4.85,7.2,7.65,8,.7,PALETTE[1]),(4.85,6.4,7.65,5,.9,PALETTE[3]),(4.85,5.8,7.65,2,.6,PALETTE[4]),(4.85,3.0,7.65,5,.45,PALETTE[3]),(4.85,2.5,7.65,2,.55,PALETTE[3])];for (x0,y0,x1,y1,w,c) in flows xs=range(x0,x1,length=80);ys=[(1-u)*y0+u*y1+sin(pi*u)*(.35sign(y1-y0)) for u in range(0,1,length=80)];band!(ax,xs,ys.-w/2,ys.+w/2;color=with_alpha(c,.28)) end;fig
end

function volume_slices()
    fig=Figure(size=(1600,1000),backgroundcolor=:transparent);header!(fig,3,"MAKIE · VOLUME SLICES","Tomographic field sections","Orthogonal slices, shared scale, and contour overlays reveal a synthetic volumetric structure.")
    n=120;coords=range(-3,3,length=n);vol=[exp(-((x+1)^2+y^2+z^2))+.8exp(-((x-1.2)^2+(y-.5)^2+(z+.4)^2)*1.4)+.25sin(3x+2y-z) for x in coords,y in coords,z in coords];slices=[vol[:,:,60],vol[:,55,:],vol[70,:,:]];titles=["axial z=0","coronal y=-0.2","sagittal x=0.5"];last=nothing;for i in 1:3 ax=Axis(fig[4,i];aspect=DataAspect(),title=titles[i],xlabel="coordinate",ylabel="coordinate");last=heatmap!(ax,coords,coords,slices[i];colormap=:magma);contour!(ax,coords,coords,slices[i];levels=9,color=RGBAf(1,1,1,.35),linewidth=1) end;Colorbar(fig[5,1:3],last;vertical=false,label="field intensity",width=Relative(.6));fig
end

function molecular_scene()
    fig=Figure(size=(1600,1000),backgroundcolor=:transparent);header!(fig,2,"MAKIE · MOLECULAR SCENE","Molecular geometry and bond network","Atom class, bond order, and functional-group geometry share one publication-scale 3D view.")
    ax=Axis3(fig[4,1];azimuth=1.25pi,elevation=.2pi,aspect=(1.5,1,.7),xypanelcolor=:transparent,xzpanelcolor=:transparent,yzpanelcolor=:transparent);pts=[Point3f(cos(i*.78)*(1+.08i),sin(i*.78)*(1+.05i),.55sin(i*.39)) for i in 1:28];cols=[[:teal,:hotpink,:cornflowerblue,:gold][mod1(i,4)] for i in 1:28];meshscatter!(ax,pts;color=cols,markersize=[.18+.04mod(i,5) for i in 1:28]);for i in 2:28 lines!(ax,[pts[i-1],pts[i]];color=RGBAf(.35,.5,.62,.65),linewidth=4) end;for i in 5:6:28 lines!(ax,[pts[i],pts[mod1(i+7,28)]];color=RGBAf(1,.65,.3,.6),linewidth=2) end;Legend(fig[4,2],[MarkerElement(color=c,marker=:circle,markersize=20) for c in [:teal,:hotpink,:cornflowerblue,:gold]],["carbon","oxygen","nitrogen","functional group"]);colsize!(fig.layout,1,Relative(.86));fig
end

function polar_climate()
    fig=Figure(size=(1600,1000),backgroundcolor=:transparent);header!(fig,2,"MAKIE · POLAR ANALYSIS","Seasonal climate wheel","Direction, month, magnitude, and uncertainty are aligned in a radial small-multiple composition.")
    ax=PolarAxis(fig[4,1];title="Directional intensity by month");theta=range(0,2pi,length=145);for m in 1:12 r=@. 1.2+.07m+.45sin(3theta+m*.4)+.18cos(7theta-m);lines!(ax,theta,r;color=with_alpha(PALETTE[mod1(m,4)],.38),linewidth=2) end;bars=Axis(fig[4,2];xlabel="month",ylabel="mean intensity",title="Monthly aggregate");vals=[1.4+.45sin(m*.55)+.15cos(m*1.8) for m in 1:12];barplot!(bars,1:12,vals;color=vals,colormap=:turbo);fig
end

function gantt_system()
    fig=Figure(size=(1600,1000),backgroundcolor=:transparent);header!(fig,1,"MAKIE · PROGRAM TIMELINE","Mission program dependency map","Workstreams, decision gates, milestones, and slack are composed as a dense planning figure.")
    ax=Axis(fig[4,1];limits=(0,20,0,11),xticks=0:2:20,yticks=(1:10,["Science","Design","Prototype","Flight","Comms","Ground","Data","Safety","Public","Review"]),xlabel="program month",title="Integrated delivery plan");starts=[0,1,3,5,7,2,8,6,12,16];dur=[5,6,5,7,4,8,6,7,4,3];for i in 1:10 poly!(ax,Rect2f(starts[i],i-.32,dur[i],.64);color=with_alpha(PALETTE[mod1(i,4)],.55),strokecolor=INK,strokewidth=1);text!(ax,"P$(lpad(string(i),2,'0'))";position=(starts[i]+.25,i),align=(:left,:center),color=INK,fontsize=13);if i<10 lines!(ax,[Point2f(starts[i]+dur[i],i),Point2f(starts[i+1],i+1)];color=RGBAf(INK.r,INK.g,INK.b,.35),linestyle=:dash) end end;vlines!(ax,[5,10,15];color=ACCENT,linewidth=2,linestyle=:dot);fig
end

function topology_graph()
    fig=Figure(size=(1600,1000),backgroundcolor=:transparent);header!(fig,1,"MAKIE · GRAPH TOPOLOGY","Layered compute topology","Clusters, cross-links, centrality, and edge classes form a reusable systems reference.")
    ax=Axis(fig[4,1];limits=(-6,6,-4,4),aspect=DataAspect(),title="Service and data dependency field");hidedecorations!(ax);hidespines!(ax);pts=[Point2f(cos(i*2.399)*(1+.07i),sin(i*2.399)*(1+.05i)) for i in 1:46];for i in 2:46 lines!(ax,[pts[i],pts[mod1(i*7,46)]];color=RGBAf(.35,.5,.65,.18+(i%4)*.05),linewidth=1+(i%3));if i%5==0 lines!(ax,[pts[i],pts[mod1(i+13,46)]];color=RGBAf(1,.45,.58,.35),linestyle=:dash) end end;scatter!(ax,pts;color=[mod1(i,5) for i in 1:46],colormap=[:teal,:cornflowerblue,:hotpink,:gold,:orchid],markersize=[12+mod(i*7,22) for i in 1:46],strokecolor=:white,strokewidth=1);fig
end

const DEMOS = Dict(
    "surface-terrain" => surface_terrain,
    "vector-field" => vector_field,
    "phase-dashboard" => phase_dashboard,
    "uncertainty-forecast" => uncertainty_forecast,
    "correlation-matrix" => correlation_matrix,
    "parallel-coordinates" => parallel_coordinates,
    "sankey-energy" => sankey_energy,
    "volume-slices" => volume_slices,
    "molecular-scene" => molecular_scene,
    "polar-climate" => polar_climate,
    "gantt-system" => gantt_system,
    "topology-graph" => topology_graph,
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
