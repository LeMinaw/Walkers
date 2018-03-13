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

const version = "1.0.0"

@enum Laws position=0 acceleration=1 newton=2

@enum Relations onetoone=0 manytomany=1 electronic=2

function /(k::Int, pt::Point{})
    k ./ pt
end

"Replaces all"
function replacenan!(mat::Array{T}) where T
    mat[isnan(x)] = zero(T)
end

"Returns a copy of `mat` with all coeficients on the diagonal equals to zero."
function nulldiag(mat::Array)
    triu(mat, 1) + tril(mat, -1)
end

"Returns a copy of an array `mat` (containing objects on wich a norm is
defined) where all objects have a norm of 1."
function normalize(mat::Array)
    mat ./ norm.(mat)
end

"Maps `x` from the range `[0, 1]` to `[avg-width, avg+width]`."
function scatter(x::Any, avg=0::Real, width=1::Rand)
    x * 2width - width + avg
end

"Returns a copy of `mat` where columns order is randomly shuffled."
function shufflecols(mat::Array{T, 2}) where T
    mat[:, randperm(size(mat, 2))]
end

"""
Returns an copy of `mat` where columns are offset to the left.

# Exemple
```julia-repl
julia> a = [1 2 3;
            4 5 6]
julia> offsetcols(a)
2 3 1
5 6 4
```
"""
function offsetcols(mat::Array{T, 2}) where T
    if size(mat, 2) == 1
        return mat
    end
    perms = collect(2:size(mat, 2))
        push!(perms, 1)
    mat[:, perms]
end

"""
Returns a square matrix of all differences of the elements provided in the `mat`
column matrix or vector.

# Exemple
```julia-repl
julia> diffs([a; b; c])
a-a b-a c-a
a-b b-b c-b
a-c b-c c-c
```
"""
function diffs(mat::Array)
    dupl = repmat(mat, 1, size(mat, 1))
    transpose(dupl) - dupl
end

function walk(law::Laws, n::Int, pos::Array, rels::Array)
    states = Point3f0[]
    vel = fill(Vec3f0(0, 0, 0), length(pos))
    for i = 1:n
        append!(states, pos)
        # TODO: Experiment again with this relation:
        # pos += rels * pos - transpose(transpose(pos) * rels)
        # TODO: Add option to normalize, eg:
        # acc = sum(10rels .* (nulldiag(normalize(dist))), 2)
        if law == position
            # Increases position by a part of the distance
            pos += rels * pos - sum(rels, 2) .* pos
        else
            dist = diffs(pos)
            if law == newton
                # Newton's and Coulomb's law is of form k/d²
                dist = 100^2 * nulldiag(normalize(dist) .* norm.(dist) .^ -1)
            end
            vel += sum(.1rels .* dist, 2)
            pos += vel
        end
    end
    states
end

Base.@ccallable function app()::Cint # For compilation with PackageCompiler
    # OpenGL interface init
    window = glscreen("Walkers Alpha v$(version)")

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
    law_gui,        law_s        = widget(Signal(position),                     editscreen)
    relation_gui,   relation_s   = widget(Signal(onetoone),                     editscreen)
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
        "Relation model" => relation_gui,
        "Dynamics law"   => law_gui,
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
    relations_s = map(walkers_s, relation_s, attrac_s, variance_s, seed_s) do n, model, avg, var, seed
        srand(rng, seed) # Inits local RNG
        if model == onetoone
            rel = offsetcols(eye(n))
        elseif model == electronic
            loads = repmat(rand(rng, n), 1, n)
            rel = -transpose(loads) .* loads
        else
            rel = rand(rng, n, n)
        end
        scatter.(rel, avg, var)
    end

    states_s = map(law_s, iterations_s, points_s, relations_s) do law, iters, pts, rels
        walk(map(value, (law, iters, pts, rels))...)
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
