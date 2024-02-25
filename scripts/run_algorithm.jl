using DrWatson
@quickactivate "vkr"
include(srcdir("vkr.jl"))

allparams = Dict(
    :mutations => [gene_mutation, swapping_mutation, full_mutation],
    :crossovers => [multipoint(2), multipoint(3), multipoint(5)]
)

dicts = dict_list(allparams)
