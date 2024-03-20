### TYPES

const Vertex = Int
const Color = Int
const Coloring = Vector{Color}
const SomeColoring = Vector{Union{Color, Nothing}}
const SMALLEST_COLOR = 0::Color

### end TYPES


### CRITERIONS

color_count(coloring) = length(unique!(sort(coloring)))

function color_count_with_penalty(graph::Graphs.AbstractGraph; weight = 1) 
    edges = Graphs.edges(graph)

    (coloring::Vector{Int64}) -> begin
        penalty = foldxl(
            +,
            edges
            |> Filter(edge -> coloring[Graphs.src(edge)] == coloring[Graphs.dst(edge)])
            |> Map(edge -> weight);
            init = 0
        )

        color_count(coloring) + penalty
    end
end

### end CRITERIONS


### POPULATION GENERATORS

greedy_coloring(ordering_strategy) = (graph) -> begin
    vertices = ordering_strategy(graph)
    coloring = Vector{Union{Int, Nothing}}(nothing, length(vertices))

    for vertex in vertices
        coloring[vertex] = smallest_color(graph, vertex, coloring)
    end

    coloring
end

function smallest_color(graph, vertex, coloring)
    neighbours = Graphs.neighbors(graph, vertex)
    neighbour_colors = neighbours |>
        Map(neighbour -> coloring[neighbour]) |>
        NotA(Nothing) |>
        Unique() |>
        collect

    if isempty(neighbour_colors)
        return 0
    end

    sort!(neighbour_colors)

    color = 0

    for i in eachindex(neighbour_colors)
        if color != neighbour_colors[i] break end
        color += 1
    end

    color
end

function randomized_lf_ordering(graph)
    vertices = Graphs.vertices(graph)
    degrees = vertices |> Map(vertex -> Graphs.degree(graph, vertex)) |> tcollect

    ordering = Vector{Int}

    while !isempty(vertices)
        idx = roulette_idx(degrees)
        push!(ordering, vertices[idx])

        deleteat!(vertices, idx)
        deleteat!(degrees, idx)
    end

    ordering
end

# function randomized_sl_ordering(graph)
#     vertices = Graphs.vertices(graph)
#     ordering = Vector{Int}

#     while length(ordering) != length(vertices)
#         weights = vertices |>
#             Map(vertex -> Graphs.degree(graph, vertex)) |>  # WRONG! GRAPH SHOULD BE WITHOUT ALREADY ADDED VERTICES
#             Map(inv) |>
#             tcollect

#         idx = roulette_idx(weights)
#         push!(ordering, vertices[idx])

#         deleteat!(vertices, idx)
#     end

#     reverse!(ordering)
#     ordering
# end

random_ordering(graph) = Random.shuffle!(tcollect(Graphs.vertices(graph)))

### end POPULATION GENERATORS
