using Random, LinearAlgebra


"Returns a copy of `mat` with all coeficients on the diagonal equals to zero."
function nulldiag(mat::AbstractMatrix)
    @assert size(mat, 1) == size(mat, 2)
    mat .* .!I(size(mat, 1))
end

"Returns a copy of an array `mat` (containing objects on wich a norm is
defined) where all objects have a norm of 1."
function normalize(mat::Array)
    mat ./ norm.(mat)
end

"Returns a copy of `mat` where columns order is randomly shuffled."
function shufflecols(mat::AbstractMatrix)
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
function offsetcols(mat::AbstractMatrix)
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
function diffs(mat::AbstractMatrix)
    dupl = repeat(mat, 1, size(mat, 1))
    permutedims(dupl) - dupl
end
