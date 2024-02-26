using DrWatson
@quickactivate "vkr"
include(srcdir("vkr.jl"))

get_edge_count(n, ρ) = round(Int, (1 - ρ) * (n - 1) + ρ * n * (n - 1) / 2)

allparams = Dict(
    :vertex_count => [50, 150, 250, 350],
    :ρ => [0.1, 0.3, 0.6, 0.8],
    :count => collect(1:100)
)

dicts = dict_list(allparams)

function generate_graph(vertex_count, ρ)
    edge_count = get_edge_count(vertex_count, ρ)
    graph = Graphs.SimpleGraph(vertex_count, edge_count)
    graph
end

function save_graph(dict::Dict)
    @unpack vertex_count, ρ, count = dict
    graph = generate_graph(vertex_count, ρ)
    Graphs.savegraph(joinpath("data/graphs", savename(dict, "txt")), graph)
end

Threads.@threads for (i, d) in enumerate(dicts)
    save_graph(d)
end
