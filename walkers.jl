module Walkers

const version = "2.1.0"


using GLMakie, GLFW, FileIO
using LinearAlgebra, Colors
using Random: seed!
import Base./

include("matutils.jl")


const NaNPoint3f0 = Point3f0(NaN32, NaN32, NaN32)

@enum Laws position=0 velocity=1 newtonlinear=2 newton=3 cyclical=4

@enum Relations onetoone=0 sparse=1 manytomany=2 electronic=3


"Display an observable each time it is changed."
monitor = obs::Observable -> on(display, obs)

"Return the values of multiple labeled sliders."
function ls_values(sliders...)
    [s.slider.value for s in sliders]
end

"Return the layouts of multiple labeled sliders."
function ls_layouts(sliders...)
    [s.layout for s in sliders]
end

"Defines broadcast on real by point division."
function /(x::Real, pt::Point{})
    x ./ pt
end

"Maps `x` from the range `[0, 1]` to `[avg-width, avg+width]`."
function scatter(x::Any, avg=0::Real, width=1::Real)
    width * (2x .- 1) .+ avg
end

"Builds a linear random hue colormap of `steps` elements."
function huecolmap(steps=2; s=1.0, l=0.5, a=1.0)
    hues = range(rand(0:359), stop=rand(0:359), length=steps)
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
            pos += rels * pos - sum(rels .* pos, dims=2)
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
            vel += sum(.1rels .* forces, dims=2)
            pos += vel
        end
    end
    states
end

function app()
    set_window_config!(
        title = "Walkers Alpha",
        decorated = true,
        # renderloop = renderloop,
    )

    set_theme!(
        fontsize = 14,
        colgap = 0,
        rowgap = 0
    )

    app_scene = Scene(camera=campixel!)
    
    app_layout = GridLayout(
        app_scene,
        2, 2,
        colsizes = [Fixed(400), Auto()]
    )

    view_scene = LScene(app_scene, camera=cam3d!, raw=false)
    view_scene.scene[:show_axis] = false

    count_ls    = labelslider!(app_scene, "Walkers count",       2:40;                       sliderkw=Dict(:startvalue=>5))
    spread_ls   = labelslider!(app_scene, "Walkers spread",      LinRange(0f0, 100f0, 101);  sliderkw=Dict(:startvalue=>50f0))
    rel_avg_ls  = labelslider!(app_scene, "Average attraction",  LinRange(-.1f0, .1f0, 101); sliderkw=Dict(:startvalue=>0f0))
    rel_var_ls  = labelslider!(app_scene, "Attraction variance", LinRange(0f0, 1f0, 101);    sliderkw=Dict(:startvalue=>0f0))
    iters_ls    = labelslider!(app_scene, "Iterations",          2:1000;                     sliderkw=Dict(:startvalue=>10))
    rotspeed_ls = labelslider!(app_scene, "Rotation speed",      LinRange(0f0, 1f0, 101);    sliderkw=Dict(:startvalue=>.2f0))

    settings_layout = GridLayout(
        tellheight = false,
        alignmode = Outside(10),
    )

    settings_layout[1:6, 1] = ls_layouts(count_ls, spread_ls, rel_avg_ls, rel_var_ls, iters_ls, rotspeed_ls)
    
    
    app_layout[1, 1] = Box(app_scene, color=(:black, .04), strokevisible=false)
    app_layout[1, 1] = settings_layout
    app_layout[1, 2] = view_scene
    app_layout[2, 1:2] = Box(app_scene, color=RGBA(0, 0, 0, .08), strokevisible=false)
    app_layout[2, 1:2] = Label(app_scene, "Welcome to Walkers Alpha!", alignmode=Outside(3))

    #=
        # GUI parameters
        speed_gui,      speed_s      = textslider(0:.1:10,            editscreen)
        # cmap_gui,       cmap_s       = widget(default_cmap,               editscreen)
        # path_color_gui, path_color_s = widget(Signal(default_path_color), editscreen)
        # law_gui,        law_s        = widget(Signal(position),           editscreen)
        # relation_gui,   relation_s   = widget(Signal(onetoone),           editscreen)
        center_gui,     center_s     = button("⛶",                        editscreen)
        regen_gui,      regen_s      = button("↻",                        editscreen)
        params = Pair[
            "Rotation speed" => speed_gui,
            "Color map"      => cmap_gui,
            "Paths color"    => path_color_gui,
            "Relation rel_model" => relation_gui,
            "Dynamics law"   => law_gui,
            "Center"         => center_gui,
            "Regenerate"     => regen_gui
        ]

        # DEBUG
        # speed_s      = Signal(1)
        # cmap_s       = Signal()
        # center_s     = Signal(false)
        # regen_s      = Signal(false)

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
    =#

    seed = 13121312
    law = position
    rel_model = onetoone
    rings_colors_stops::Array{RGBAf0, 1} = [
        RGBA(.27, .01, .33, .7),
        RGBA(.13, .56, .55, .6),
        RGBA(.99, .91, .14, .4)
    ]
    paths_color = RGBA(.1, .1, .1, .8)

    # RNG
    rng = MersenneTwister(0)

    # Init points
    points = lift(ls_values(count_ls, spread_ls)...) do count, spread
        seed!(rng, seed)
        scatter.(rand(rng, Point3f0, count), 0, spread)
    end

    # Relations matrix mask
    rels_mask = lift(ls_values(count_ls)...) do n
        seed!(rng, seed + 1)
        if rel_model == onetoone
            # One walker is in relation with another
            mask = offsetcols(collect(I(n)))
        elseif rel_model == sparse
            # Sparse is ManyToMany with only 25% of relations.
            # As the diagonal will be nulled, compensation is needed.
            mask = rand(rng, Float32, n, n) .< .25f0 + 1f0/n
        # elseif rel_model == electronic
        #     # Relation matrix as if each walker behaves as a +/- charged particule
        #     loads = repeat(rand(rng, n), 1, n)
        #     rel = -transpose(loads) .* loads
        else
            # Each walker is in relation with all others
            mask = trues(n, n)
        end
        nulldiag(mask)
    end

    # Relations matrix
    relations = lift(ls_values(count_ls, rel_avg_ls, rel_var_ls)..., rels_mask) do n, avg, var, mask
        seed!(rng, seed + 2)
        rels = scatter.(rand(rng, Float32, n, n), avg, var)
        rels .* mask
    end

    # System states
    last_states::Union{Array{Point3f0, 2}, Nothing} = nothing
    states = lift(ls_values(count_ls, iters_ls)..., points, relations) do n, iters, points, relations
        if length(points) == size(relations, 1)
            states = walk(law, iters, points, relations)
            states = reshape(states, n, iters)
            last_states = states
            return states
        else
            return last_states
        end
    end

    # Geometry
    rings_vertex = @lift begin
        rings = vcat($states, $states[1:1, :])
        rings = vcat(rings, fill(NaNPoint3f0, (1, size(rings, 2))))
        reshape(rings, length(rings))
    end
    paths_vertex = @lift begin
        paths = hcat($states, fill(NaNPoint3f0, size($states, 1)))
        reshape(permutedims(paths), length(paths))
    end

    # Colors
    rings_color = @lift to_colormap(rings_colors_stops, length($rings_vertex))

    # Plotting
    rings = lines!(view_scene, rings_vertex, color=rings_color, transparency=true, linewidth=2)
    paths = lines!(view_scene, paths_vertex, color=paths_color, transparency=true, linewidth=3)

    # Controls
    controls = cameracontrols(view_scene.scene)
    controls.rotationspeed[]= .02

    # Run app
    display(app_scene)

    # Autorotate
    angle = lift(rotspeed_ls.slider.value) do speed
        speed / 5f1
    end
    while isopen(view_scene.scene)
        rotate_cam!(view_scene.scene, to_value(angle), 0f0, 0f0)
        sleep(.01)
    end
end

app() # For tesing purposes, should be removed when compiling

end
