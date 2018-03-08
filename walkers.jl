module Walkers

using GLAbstraction, Colors, GeometryTypes, GLVisualize, Reactive, GLWindow
import GLVisualize: mm, widget, button, slider, labeled_slider
import Base./
# import Colors: RGBA, colormap
# import GeometryTypes: Vec2f0, Point3f0
# import Reactive: Signal, map, value, preserve
# import GLWindow: Screen
# import GLAbstraction: rotationmatrix_z
# import GLVisualize: glscreen, _view, visualize, renderloop, x_partition_abs, loop, center!

function /(k::Int, pt::Point{})
    k ./ pt
end

function replacenan!{T}(mat::Array{T})
    mat[isnan(x)] = zero(T)
end

function nulldiagonal{T}(mat::Array{T})
    triu(mat, 1) + tril(mat, -1)
end

function normalize{T}(mat::Array{T})
    r = nulldiagonal(mat ./ norm.(mat))
end

function scatter(x::Any, avg=0::Real, width=1::Rand)
    x * 2width - width + avg
end

function shufflecols(mat::Array{T, 2}) where T
    mat[:, randperm(size(mat, 2))]
end

function offsetcols(mat::Array{T, 2}) where T
    if size(mat, 2) == 1
        return mat
    end
    perms = collect(2:size(mat, 2))
    push!(perms, 1)
    mat[:, perms]
end

function walk(n, pos, rels)
    states = Point3f0[]
    vel = fill(Vec3f0(0, 0, 0), length(pos))
    for i = 1:n
        append!(states, pos)
        # pos += rels * pos - transpose(transpose(pos) * rels)
        # pos += rels * pos - sum(rels, 2) .* pos
        # d = norm.(100rels * pos - sum(100rels, 2) .* pos)
        dist = repmat(pos, 1, size(pos, 1))
        dist = transpose(dist) - dist
        acc = sum(10rels .* (normalize(dist)), 2)

        vel += acc
        pos += vel
    end
    states
end

Base.@ccallable function app()::Cint # For compilation with PackageCompiler
    # OpenGL interface init
    window = glscreen("Walkers Alpha v1.0.0")

    # GUI layout
    editarea, viewarea = x_partition_abs(window.area, 70mm)
    editscreen = Screen(
        window, area = editarea,
        color = RGBA{Float32}(0.98, 0.98, 0.98, 1)
    )
    viewscreen = Screen(window, area=viewarea)

    # GUI parameters
    speed_gui,      speed_s      = labeled_slider(0:.1:10,                      editscreen)
    walkers_gui,    walkers_s    = labeled_slider(2:1:40,                       editscreen)
    iterations_gui, iterations_s = labeled_slider(2:1:1000,                     editscreen)
    spread_gui,     spread_s     = labeled_slider(0:.1:100,                     editscreen)
    attrac_gui,     attrac_s     = labeled_slider(-.05:.001:.05,                editscreen)
    variance_gui,   variance_s   = labeled_slider(0:.001:.1,                    editscreen)
    cmap_gui,       cmap_s       = widget(RGBA{Float32}.(colormap("Reds", 5)),  editscreen)
    center_gui,     center_s     = button("⛶",                                  editscreen)
    regen_gui,      regen_s      = button("↻",                                  editscreen)
    params = Pair[
        "Rotation speed" => speed_gui,
        "Walkers number" => walkers_gui,
        "Iterations"     => iterations_gui,
        "Walkers spread" => spread_gui,
        "Attraction"     => attrac_gui,
        "Variance"       => variance_gui,
        "Color map"      => cmap_gui,
        "Center"         => center_gui,
        "Regenerate"     => regen_gui
    ]
    menu = visualize(params)
    _view(menu, editscreen, camera=:fixed_pixel)

    # DEBUG
    # speed_s      = Signal(1)
    # walkers_s    = Signal(3)
    # iterations_s = Signal(4)
    # spread_s     = Signal(100)
    # attrac_s     = Signal(.01)
    # variance_s   = Signal(0)
    # cmap_s       = Signal()
    # center_s     = Signal(false)
    # regen_s      = Signal(false)

    # Random number generator initialisation
    seed_s = Signal(abs(rand(Int32)))
    rng = MersenneTwister(0)

    # Buttons actions
    preserve(map(center_s, regen_s) do center, regen # preserve() avoids GC
        if center
            center!(viewscreen)
        elseif regen
            seed = abs(rand(Int32)) # Uses the global RNG
            push!(seed_s, seed)
        end
        nothing
    end)

    # Computation and signals mappings
    time_s = loop(linspace(0f0, Float32(typemax(Int32)), typemax(Int32)))
    rot_s = map(time_s, speed_s) do t, s
        rotationmatrix_z(Float32(t * s/360)) # -> 4x4 Float32 rotation matrix
    end

    points_s = map(walkers_s, spread_s, seed_s) do n, spread, seed
        srand(rng, seed) # Inits local RNG
        scatter.(rand(rng, Point3f0, n), 0, spread)
    end
    relations_s = map(walkers_s, attrac_s, variance_s, seed_s) do n, attrac, variance, seed
        srand(rng, seed) # Inits local RNG # scatter.(rand(rng, n, n), attrac, variance)
        scatter.(offsetcols(eye(n)), attrac, variance)
    end

    states_s = map(iterations_s, points_s, relations_s) do iters, pts, rels
        walk(map(value, (iters, pts, rels))...)
    end
    rings_s = map(states_s, iterations_s, walkers_s) do states, iters, wlkrs
        reshape(states, wlkrs, iters)
    end
    lines_s = map(rings_s) do states
        transpose(states)
    end
    cnorm_s = map(iterations_s) do iters
        Vec2f0(1, iters/1024)
    end

    # Plotting
    lines = visualize(
        lines_s, :lines,
        intensity = [0f0, 0f0],
        color_map = [RGBA{Float32}(0, 0, 0, 0.8), RGBA{Float32}(0, 0, 0, 0.8)],
        color_norm = Vec2f0(0, 1),
        model = rot_s,
    )
    rings = visualize(
        rings_s, :lines,
        intensity = collect(linspace(0f0, 1f0, 1024)),
        color_map = cmap_s,
        color_norm = cnorm_s,
        model = rot_s,
    )
    _view(lines, viewscreen, camera=:perspective)
    _view(rings, viewscreen, camera=:perspective)

    renderloop(window)
    return 0
end

app() # For tesing purposes, should be removed when compiling

end
