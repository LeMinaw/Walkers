module Walkers

using GLAbstraction, Colors, GeometryTypes, GLVisualize, Reactive, GLWindow, GLFW
import GLVisualize: mm, widget, button, slider, labeled_slider
import GLFW: KEY_S
import Base./
# import Colors: RGBA, colormap
# import GeometryTypes: Vec2f0, Point3f0
# import Reactive: Signal, map, value, preserve
# import GLWindow: Screen
# import GLAbstraction: rotationmatrix_z
# import GLVisualize: glscreen, _view, visualize, renderloop, x_partition_abs, loop, center!

include("matutils.jl")

const version = "1.1.0"

@enum Laws position=0 velocity=1 newtonlinear=2 newton=3 cyclical=4

@enum Relations onetoone=0 sparse=1 manytomany=2 electronic=3

"Defines broadcast on real by point division."
function /(x::Real, pt::Point{})
    x ./ pt
end

"Maps `x` from the range `[0, 1]` to `[avg-width, avg+width]`."
function scatter(x::Any, avg=0::Real, width=1::Rand)
    x * 2width - width + avg
end

"Builds a linear random hue colormap of `steps` elements."
function huecolmap(steps=2; s=1.0, l=0.5, a=1.0)
    hues = linspace(rand(0:359), rand(0:359), steps)
    cmap = Array{RGBA}(steps)
    for i = 1:steps
        color = HSLA(hues[i], s, l, a)
        cmap[i] = convert(RGBA, color)
    end
    cmap
end

"Computes walkers states."
function walk(law::Laws, n::Int, pos::Array, rels::Array)
    states = Point3f0[]
    vel = fill(Vec3f0(0, 0, 0), length(pos)) # Null initial velocity
    for i = 1:n
        append!(states, pos)
        if law == position
            # A specific part of the distance between a walker and the others
            # will be added to its position.
            pos += rels * pos - sum(rels .* pos, 2)
        elseif law == cyclical
            # Alg that does not uses attraction directly but variances between
            # attraction values as position modulation.
            pos += rels * pos - transpose(transpose(pos) * rels)
        else
            forces = diffs(pos) # Distance between all walkers locations
            if law == newton || law == newtonlinear
                # Newton's and Coulomb's forces norms are of form k/d².
                # newtonlinear is variation of form k/d
                # normalize(f) returns a direction vector of norm 1, while
                # norm.(f).^pow is the norm of the new force vector.
                pow = law == newton ? -2 : -1
                forces = 10^4 * nulldiag(normalize(forces) .* norm.(forces) .^ pow)
            end
            # Forces are modulated by walkers relations, then instant velocity
            # is incremented by the resulting acceleration. Position is then
            # incremented by instant velocity.
            vel += sum(.1rels .* forces, 2)
            pos += vel
        end
    end
    states
end

Base.@ccallable function app()::Cint # For compilation with PackageCompiler
    # OpenGL interface init
    window = glscreen("Walkers Alpha v$(version)")

    # GUI layout
    editarea, viewarea = x_partition_abs(window.area, 90mm)
    editscreen = Screen(
        window,
        area = editarea,
        color = RGBA{Float32}(0.98, 0.98, 0.98, 1)
    )
    viewscreen = Screen(window, area=viewarea)

    # Default color map
    default_cmap = RGBA{Float32}.(huecolmap(5, a=.2))

    # GUI parameters
    speed_gui,      speed_s      = labeled_slider(0:.1:10,        editscreen)
    walkers_gui,    walkers_s    = labeled_slider(2:1:40,         editscreen)
    iterations_gui, iterations_s = labeled_slider(2:1:1000,       editscreen)
    spread_gui,     spread_s     = labeled_slider(0:.1:100,       editscreen)
    attrac_gui,     attrac_s     = labeled_slider(-.05:.0001:.05, editscreen)
    variance_gui,   variance_s   = labeled_slider(0:.0001:.1,     editscreen)
    cmap_gui,       cmap_s       = widget(default_cmap,           editscreen)
    law_gui,        law_s        = widget(Signal(position),       editscreen)
    relation_gui,   relation_s   = widget(Signal(onetoone),       editscreen)
    center_gui,     center_s     = button("⛶",                    editscreen)
    regen_gui,      regen_s      = button("↻",                    editscreen)
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

    # Tray button actions
    preserve(map(center_s, regen_s) do center, regen # preserve() avoids GC
        if center
            center!(viewscreen)
        elseif regen
            seed = abs(rand(Int32)) # Uses the global RNG
            push!(seed_s, seed)
        end
        nothing
    end)

    # Save stuff
    key_pressed = false
    preserve(map(window.inputs[:keyboard_buttons]) do ksam # preserve() avoids GC
       key, scancode, action, mods = ksam
       if key == GLFW.KEY_S && !key_pressed
           name = rand(0000:9999)
           screenshot(viewscreen, path="$name.png",       channel=:color)
           screenshot(viewscreen, path="$name-depth.png", channel=:depth)
           key_pressed = true
       else
           key_pressed = false
       end
       nothing
    end)

    # Time and rotation signal mappings
    time_s = loop(linspace(0f0, Float32(typemax(Int32)), typemax(Int32)))
    rot_s = map(time_s, speed_s) do t, s
        rotationmatrix_z(Float32(t * s/360)) # -> 4x4 Float32 rotation matrix
    end

    # Spread points in space at initialization
    points_s = map(walkers_s, spread_s, seed_s) do n, spread, seed
        srand(rng, seed) # Inits local RNG
        scatter.(rand(rng, Point3f0, n), 0, spread)
    end

    # Define relation matrix
    relations_s = map(walkers_s, relation_s, attrac_s, variance_s, seed_s) do n, model, avg, var, seed
        srand(rng, seed) # Inits local RNG
        # One walker is in relation with another
        if model == onetoone
            rel = offsetcols(eye(n))
        # Relation matrix as if each walker behaves as a +/- charged particule
        elseif model == electronic
            loads = repmat(rand(rng, n), 1, n)
            rel = -transpose(loads) .* loads
        # Each walker is in relation with all others
        else
            rel = rand(rng, n, n)
            # Sparse model is ManyToMany with 75% of the relations set to 0
            if model == sparse
                randzero!(rel, .75)
            end
        end
        nulldiag(scatter.(rel, avg, var))
    end

    # Mapping plotting signals
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
        lines_s,
        :lines,
        intensity = [0f0, 0f0],
        color_map = [RGBA{Float32}(0, 0, 0, 0.8), RGBA{Float32}(0, 0, 0, 0.8)],
        color_norm = Vec2f0(0, 1),
        model = rot_s,
    )
    rings = visualize(
        rings_s,
        :lines,
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
