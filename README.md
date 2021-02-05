# Walkers Alpha

Dynamic systems vizualisation software, written in Julia.

![cover](https://raw.githubusercontent.com/LeMinaw/Walkers/master/demo/arms.png)

## How to run it

### On Windows

Windows builds are planned but currently broken. You'll need [Julia](https://julialang.org/downloads/) to run the software.

<!-- Standalone Windows builds can be found in [GitHub releases](https://github.com/LeMinaw/walkers/releases).

The application takes a few moments to init, please be patient. -->

### In Julia's REPL

To run the software in Julia's REPL, please use
```julia
>>> include("walkers.jl")
>>> Walkers.julia_main()
```

*The first run will take a bit long due to JIT compilation overhead, but
following ones should take no time. If you hack into the code, it's probably
more conveniant to load Walkers from the REPL instead of using the `julia`
command from a system shell then.*

## How to use it

### Quick start

If you don't know where to start and want to experiment by yourself quickly,
try to modify these parameters.

* **Attraction:**     0.005
* **Walkers spread:** 100
* **Iterations:**     100
* **Walkers number:** 10

Then click the **Center** button.

You can now experiment with the different parameters as you want.

### Manual

#### Abstract

A walker is a point in space. Each walker is bind to another by an attraction
actor.

At each iteration, walkers walk towards other walkers who attact them, and
escape from those they flee. Black lines describe walkers' paths in time,
while color lines represent the figure they make at any time.

#### Parameters

This describes more precisely what controls do.

* **Center:**         Automatically centers and fit the 3D view.
* **Regenerate:**     Modifies initial conditions by updating the
    random number seed.
* **Color map:**      Sets colors for the rings geometry. Four channels are
    supported, RGB plus alpha (transparency). Left  values are first iterations,
    right values are last ones.
* **Variance:**       How random are attraction values. Null means no random.
* **Attraction:**     Average attraction values that binds walkers together.
    Negative value means repulsion, null means no relation, positive value is
    attraction.
* **Walkers spread:** Average distance walkers have from the origin at start.
* **Walkers number:** How many walkers the system counts.
* **Iterations:**     Number of iterations to compute.
* **Rotation speed:** Automatically rotates the 3D view on the Z axis for a
    nice screensaver effect.
