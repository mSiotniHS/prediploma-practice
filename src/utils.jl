roulette(items::AbstractVector, weights::Vector{<:Real}) =
    StatsBase.sample(default_rng(), items, StatsBase.Weights(weights))

roulette_idx(weights::Vector{<:Real}) =
    StatsBase.sample(default_rng(), StatsBase.Weights(weights))
