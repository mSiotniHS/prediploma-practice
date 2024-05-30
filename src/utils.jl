roulette(items::AbstractVector, weights::Vector{<:Real}) =
    StatsBase.sample(default_rng(), items, StatsBase.Weights(weights))

roulette_idx(weights::Vector{<:Real}) =
    StatsBase.sample(default_rng(), StatsBase.Weights(weights))

get_best = argmin

function rec_flatten_dict(d, prefix_delim = ".")
    new_d = empty(d)

    for (key, value) in pairs(d)
        if isa(value, Dict)
             flattened_value = rec_flatten_dict(value, prefix_delim)
             for (ikey, ivalue) in pairs(flattened_value)
                 new_d[ikey] = ivalue
             end
        else
            new_d[key] = value
        end
    end

    return new_d
end
