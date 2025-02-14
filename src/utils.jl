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
