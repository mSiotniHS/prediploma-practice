#region TYPES

const Vertex = Int
const Color = Int
const Coloring = Vector{Color}
const SomeColoring = Vector{Union{Color, Nothing}}
const SMALLEST_COLOR = 0::Color

#endregion


#region CRITERIONS

color_count(coloring::Coloring) = length(unique!(sort(coloring)))

function color_count_with_penalty(graph::Graphs.AbstractGraph; weight = 1) 
    edges = Graphs.edges(graph)

    fitness = let e = edges
        function f(coloring::Coloring)
            penalty = foldxl(
                +,
                e
                |> Filter(edge -> coloring[Graphs.src(edge)] == coloring[Graphs.dst(edge)])
                |> Map(edge -> weight);
                init = 0
            )

            color_count(coloring) + penalty
        end
    end

    fitness
end

#endregion


#region POPULATION GENERATORS

function random_coloring(graph::Graphs.AbstractGraph; rng::Random.AbstractRNG=default_rng())
    vertices = Graphs.vertices(graph)
    coloring = SomeColoring(nothing, length(vertices))

    for vertex in vertices
        coloring[vertex] = any_valid_color(graph, vertex, coloring; rng=rng)
    end

    coloring
end

function any_valid_color(graph::Graphs.AbstractGraph, vertex::Vertex, coloring::SomeColoring; rng::Random.AbstractRNG=default_rng())
    valid_colors = collect(range(SMALLEST_COLOR, length=Graphs.nv(graph)))
    neighbour_colors = get_non_nothing_colors(Graphs.neighbors(graph, vertex), coloring)
    setdiff!(valid_colors, neighbour_colors)

    rand(rng, valid_colors)
end

get_non_nothing_colors(vertices::Vector{Vertex}, coloring::Union{Coloring, SomeColoring}) =
    vertices |>
        Map(vertex -> coloring[vertex]) |>
        NotA(Nothing) |>
        Unique() |>
        collect


greedy_coloring(ordering_strategy) = (graph::Graphs.AbstractGraph) -> begin
    vertices = ordering_strategy(graph)
    coloring = Vector{Union{Int, Nothing}}(nothing, length(vertices))

    for vertex in vertices
        coloring[vertex] = smallest_color(graph, vertex, coloring)
    end

    coloring
end

function smallest_color(graph::Graphs.AbstractGraph, vertex::Vertex, coloring::Union{Coloring, SomeColoring})
    smallest_color(Graphs.neighbors(graph, vertex), coloring)
end

function smallest_color(neighbours::Vector{Vertex}, coloring::Union{Coloring, SomeColoring})
    neighbour_colors = get_non_nothing_colors(neighbours, coloring)

    if isempty(neighbour_colors)
        return SMALLEST_COLOR
    end

    sort!(neighbour_colors)

    @info "neighbour colors are"  neighbour_colors

    color = SMALLEST_COLOR

    for i in eachindex(neighbour_colors)
        if color != neighbour_colors[i] break end
        color += 1
    end

    @info "Smallest acceptable is"  color

    color
end

function randomized_lf_ordering(graph::Graphs.AbstractGraph)
    vertices = tcollect(Graphs.vertices(graph))
    degrees = vertices |> Map(vertex -> Graphs.degree(graph, vertex)) |> tcollect

    ordering = Vector{Int}()

    while !isempty(vertices)
        idx = roulette_idx(degrees)
        push!(ordering, vertices[idx])

        deleteat!(vertices, idx)
        deleteat!(degrees, idx)
    end

    ordering
end

function lf_ordering(graph::Graphs.AbstractGraph)
    sort(Graphs.vertices(graph), by=(vertex -> Graphs.degree(graph, vertex)), rev=true)
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

random_ordering(graph::Graphs.AbstractGraph) = Random.shuffle!(tcollect(Graphs.vertices(graph)))

#endregion


#region GRAPH GENERATION UTILITIES

function generate_vertex_degrees(μ::Float64, σ::Float64, count::Int)
    values = round.(Int, μ .+ Random.randn(count) .* σ)

    if isodd(sum(values))
        values[Random.rand(1:length(values))] += Random.rand(Bool) ? 1 : -1
    end

    return values
end

itemgetter(i::Int) = x -> x[i]
itemgetter_2 = itemgetter(2)

function generate_graph_with_vertex_degrees(vertex_degrees::Vector{Int})
    vertex_count = length(vertex_degrees)
    graph = Graphs.SimpleGraph(vertex_count)
    vertex_degrees = vertex_degrees |> Enumerate() |> collect

    while !isempty(vertex_degrees)
        sort!(vertex_degrees, by=itemgetter_2, rev=true)

        vertex, degree = vertex_degrees[1]
        for i in 2:(degree+1)
            Graphs.add_edge!(graph, vertex, vertex_degrees[i][1])
            vertex_degrees[i] = (vertex_degrees[i][1], vertex_degrees[i][2] - 1)
        end

        deleteat!(vertex_degrees, 1)
    end

    return graph
end

#endregion


#region Misc
function check_coloring(graph::Graphs.AbstractGraph, coloring::Coloring)
    for edge in Graphs.edges(graph)
        if coloring[Graphs.src(edge)] == coloring[Graphs.dst(edge)]
            @warn "Found error!"
        end
    end
end
#endregion
