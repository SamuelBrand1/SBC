# Test 1: Basic functionality
@testitem "SBC._split_namedtuple basic functionality" begin
    nt = (a = 1, b = 2, c = 3)
    selected_keys = (:a, :c)
    other_vars, selected_vars = SBC._split_namedtuple(nt, selected_keys)

    @test other_vars == (b = 2,)
    @test selected_vars == (a = 1, c = 3)
end

# Test 2: No selected keys
@testitem "SBC._split_namedtuple with no selected keys" begin
    nt = (a = 1, b = 2, c = 3)
    selected_keys = ()
    other_vars, selected_vars = SBC._split_namedtuple(nt, selected_keys)

    @test other_vars == (a = 1, b = 2, c = 3)
    @test selected_vars == NamedTuple()
end

# Test 3: All keys selected
@testitem "SBC._split_namedtuple with all keys selected" begin
    nt = (a = 1, b = 2, c = 3)
    selected_keys = (:a, :b, :c)
    other_vars, selected_vars = SBC._split_namedtuple(nt, selected_keys)

    @test other_vars == NamedTuple()
    @test selected_vars == (a = 1, b = 2, c = 3)
end

# Test 4: Selected keys not in NamedTuple
@testitem "SBC._split_namedtuple with keys not in NamedTuple" begin
    nt = (a = 1, b = 2, c = 3)
    selected_keys = (:d, :e)
    other_vars, selected_vars = SBC._split_namedtuple(nt, selected_keys)

    @test other_vars == (a = 1, b = 2, c = 3)
    @test selected_vars == NamedTuple()
end

# Test 5: Mixed keys
@testitem "SBC._split_namedtuple with mixed keys" begin
    nt = (a = 1, b = 2, c = 3, d = 4)
    selected_keys = (:b, :d)
    other_vars, selected_vars = SBC._split_namedtuple(nt, selected_keys)

    @test other_vars == (a = 1, c = 3)
    @test selected_vars == (b = 2, d = 4)
end

@testitem "SBC._nt_lfold_fn basic functionality" begin
    # Define test cases
    acc_nt = (a = [1, 2], b = [3, 4])
    sample_nt = (a = 3, b = 5)

    # Expected result
    expected_nt = (a = [1, 2, 3], b = [3, 4, 5])

    # Run the function
    result_nt = SBC._nt_lfold_fn(acc_nt, sample_nt)

    # Check the result
    @test result_nt == expected_nt
end

@testitem "SBC._full_pairs_form basic functionality" begin
    # Test case 1: Scalar values
    primary = (primary_target = (a = 1, b = 2),)
    result = SBC._full_pairs_form(primary)
    expected = [Pair(:a, 1), Pair(:b, 2)]
    @test result == expected

    # Test case 2: Array values
    primary = (primary_target = (a = [1, 2], b = [3, 4]),)
    result = SBC._full_pairs_form(primary)
    expected = [Pair(Symbol("a[1]"), 1), Pair(Symbol("a[2]"), 2),
        Pair(Symbol("b[1]"), 3), Pair(Symbol("b[2]"), 4)]
    @test result == expected

    # Test case 3: Mixed scalar and array values
    primary = (primary_target = (a = 1, b = [2, 3]),)
    result = SBC._full_pairs_form(primary)
    expected = [Pair(:a, 1), Pair(Symbol("b[1]"), 2), Pair(Symbol("b[2]"), 3)]
    @test result == expected

    # Test case 4: Multi-dimensional array values
    primary = (primary_target = (a = [1 2; 3 4],),)
    result = SBC._full_pairs_form(primary)
    expected = [Pair(Symbol("a[1, 1]"), 1), Pair(Symbol("a[1, 2]"), 2),
        Pair(Symbol("a[2, 1]"), 3), Pair(Symbol("a[2, 2]"), 4)]
    @test setdiff(result, expected) |> isempty #invariant test to ordering
end
