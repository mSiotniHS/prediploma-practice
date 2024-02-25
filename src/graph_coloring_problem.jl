### CRITERIONS

color_count(coloring) = length(unique!(sort(coloring)))

color_count_with_penalty(graph) = (coloring) -> begin
    penalty = foldxl(
        +,
        Graphs.edges(graph)
        |> Filter(edge -> coloring[Graphs.src(edge)] == coloring[Graphs.dst(edge)])
        |> Map(edge -> 1)
    )

    color_count(coloring) + penalty
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
        Filter(!isnothing) |>
        Unique() |>
        tcollect

    sort!(neighbour_colors)

    color = 0

    for neighbour_color in 1:eachindex(neighbour_colors)
        if color != neighbour_color break end
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

function randomized_sl_ordering(graph)
    vertices = Graphs.vertices(graph)
    ordering = Vector{Int}

    while length(ordering) != length(vertices)
        weights = vertices |>
            Map(vertex -> Graphs.degree(graph, vertex)) |>  # WRONG! GRAPH SHOULD BE WITHOUT ALREADY ADDED VERTICES
            Map(inv) |>
            tcollect

        idx = roulette_idx(weights)
        push!(ordering, vertices[idx])

        deleteat!(vertices, idx)
    end

    reverse!(ordering)
    ordering
end

### end POPULATION GENERATORS
