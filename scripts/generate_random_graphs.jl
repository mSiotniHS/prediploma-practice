using DrWatson
@quickactivate "vkr"
include(srcdir("vkr.jl"))

get_edge_count(n, ρ) = round(Int, ρ * n * (n - 1) / 2)

allparams = Dict(
    :vertex_count => 25,
    :ρ => 0.25,
    :count => collect(1:2)
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
    Graphs.savegraph(joinpath("data/graphs/test", savename(dict, "txt")), graph)
end


# const VERTEX_COUNT = 200

# allparams = Dict(
#     :average => [],
#     :std => [],
#     :count => collect(1:75)
# )

# dicts = dict_list(allparams)

# generate_vertex_degrees(μ, σ, count) = μ .+ Random.randn(count) .* σ

# function generate_graph(average, std)
#     vertex_degrees = generate_vertex_degrees(average, std, VERTEX_COUNT)

#     graph = Graphs.EmptyGraph()

#     for _ in 1:VERTEX_COUNT
#         max_degree_vertex = argmax(vertex_degrees)
#         neighbours =
#             Graph.neighbours(graph, max_degree_vertex) |>
#             Filter(neighbour -> vertex_degrees[neighbour] != 0) |>
#             tcollect

#         for i in eachindex(neighbours)
#             neighbour = neighbours[i]

#             # add vertex between max_degree_vertex and neighbours[i]
#             vertex_degrees[max_degree_vertex] -= 1
#             vertex_degrees[neighbour] -= 1
#         end
#     end

#     graph
# end

# function save_graph(dict::Dict)
#     @unpack average, std = dict
#     graph = generate_graph(average, std)
#     Graphs.savegraph(joinpath("data/graphs/vertex_degree", savename(dict, "txt")), graph)
# end

for (i, d) in enumerate(dicts)
    save_graph(d)
end
