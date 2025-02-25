"""
    _split_namedtuple(nt::NamedTuple, selected_keys::Tuple{Vararg{Symbol}}) -> (NamedTuple, NamedTuple)

Splits a `NamedTuple` into two separate `NamedTuple`s based on the provided `selected_keys`.
This is an internal function.

# Arguments
- `nt::NamedTuple`: The original `NamedTuple` to be split.
- `selected_keys::Tuple{Vararg{Symbol}}`: A tuple of symbols representing the keys to be selected for the second `NamedTuple`.

# Returns
- A tuple containing two `NamedTuple`s:
  - The first `NamedTuple` contains the key-value pairs from `nt` that are not in `selected_keys`.
  - The second `NamedTuple` contains the key-value pairs from `nt` that are in `selected_keys`.

"""
function _split_namedtuple(nt::NamedTuple, selected_keys::Tuple{Vararg{Symbol}})
    other_keys = setdiff(keys(nt), selected_keys) |> Tuple
    included_keys = intersect(keys(nt), selected_keys) |> Tuple
    selected_vars = NamedTuple{included_keys}(nt)
    other_vars = NamedTuple{other_keys}(nt)
    return other_vars, selected_vars
end

"""
Fold function that takes two NamedTuples and appends the values of `sample_nt` to the corresponding values in `accumulator_nt`.

# Arguments
- `accumulator_nt::NamedTuple`: The NamedTuple that accumulates the results.
- `sample_nt::NamedTuple`: The NamedTuple containing the sample values to be appended.

# Returns
- `NamedTuple`: A new NamedTuple with the same keys as `accumulator_nt` and `sample_nt`, where each value is the result of appending the corresponding values from `sample_nt` to `accumulator_nt`.
"""
function _nt_lfold_fn(accumulator_nt, sample_nt)
    pairs_form = accumulator_nt |> pairs |> collect
    new_nt = map(pairs_form) do P
        name = P.first
        acc = P.second
        return (name, append!(acc, sample_nt[name]))
    end |> NamedTuple

    return new_nt
end

"""
    _full_pairs_form(primary::NamedTuple)

Transforms a `NamedTuple` return from `run_primary_generative` method into a vector of pairs,
where each pair consists of a variable name and its corresponding target value. The function
handles both scalar values and arrays. For arrays, it generates pairs for each element, with
the variable names including the indices of the elements. This is an internal function that
complies with `MCMCChains` naming conventions.

# Arguments
- `primary::NamedTuple`: A named tuple containing the primary targets.

# Returns
- `Vector{Pair{Symbol, Any}}`: A vector of pairs, where each pair consists of a variable name (as a `Symbol`) and its corresponding value.
"""
function _full_pairs_form(primary::NamedTuple)
    pairs_form = primary.primary_target |> pairs |> collect # Names of variables whatever shape
    full_pairs_form = mapreduce(vcat, pairs_form) do p
        _name = p.first
        target = p.second
        var_sizes = size(target)
        if isempty(var_sizes) # scalar so pass through
            name = _name
            return [Pair(name, target)]
        else # Array so list all indices with MCMCChain names
            indices_strs_and_targets = map(var_sizes) do s
                1:s
            end |>
                                       iters -> Iterators.product(iters...) |>
                                                collect |>
                                                indices -> map(indices) do idx
                                                    idx_target = getindex(target, idx...)
                                                    idx_str = "[$(join(idx, ", "))]"
                                                    (; idx_str, idx_target)
                                                end
            all_pairs = mapreduce(vcat, indices_strs_and_targets) do nt
                name = Symbol(string(_name) * nt.idx_str)
                return Pair(name, nt.idx_target)
            end
            return all_pairs
        end
    end
    return full_pairs_form
end
