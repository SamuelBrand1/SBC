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
