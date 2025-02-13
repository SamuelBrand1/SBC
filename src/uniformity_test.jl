"""
Performs a chi-squared test for uniformity on the given `counts` vector given `n` bins.

# Returns
- A `HypothesisTests.PowerDivergenceTest` object representing the result of the chi-squared test.
"""
function uniformity_test(counts::Vector{Int}, n::Int)
    contingency_table = zeros(Int, n + 1)
    for val in counts
        contingency_table[val + 1] += 1
    end
    ChisqTest(contingency_table) #Default is to compare to uniform distribution
end
