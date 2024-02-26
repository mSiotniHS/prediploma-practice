### CROSSOVERS

function multipoint(point_count)
    (parent1, parent2) -> begin
        genotype_length = length(parent1)
        points = StatsBase.sample(1:(genotype_length - 1), point_count, replace=false, ordered=true)

        child1 = multipoint_core_operation(parent1, parent2, points)
        child2 = multipoint_core_operation(parent2, parent1, points)

        (child1, child2)
    end
end

function multipoint_core_operation(parent1, parent2, points)
    child = zeros(eltype(parent1), length(parent1))
    take_seconds_genes = false
    point_idx = 1

    for i in eachindex(child)
        parent = take_seconds_genes ? parent2 : parent1
        @inbounds child[i] = parent[i]

        if point_idx > length(points)
            continue
        end

        if @inbounds i == points[point_idx]
            point_idx += 1
            take_seconds_genes = !take_seconds_genes
        end
    end

    child
end

### end CROSSOVERS


### MUTATIONS

function gene_mutation(genotype)
    genotype_length = length(genotype)
    mutant = copy(genotype)

    gene_to_mutate = rand(1:genotype_length)
    @inbounds mutant[gene_to_mutate] = (genotype_length - 1) - mutant[gene_to_mutate]

    mutant
end

function swapping_mutation(genotype)
    genotype_length = length(genotype)
    mutant = copy(genotype)

    first = rand(1:genotype_length)
    second = rand(1:(genotype_length - 1))

    if second < first
        @inbounds mutant[first], mutant[second] = mutant[second], mutant[first]
    else
        @inbounds mutant[first], mutant[second + 1] = mutant[second + 1], mutant[first]
    end

    mutant
end

full_mutation(genotype) = (length(genotype) - 1) .- genotype

### end MUTATIONS


### SELECTIONS

function β_tournament(β::Int)
    (reproduction_set, manager::GaManager) -> begin
        parameters = manager.iteration_settings.parameters
        to_replace_count = round(UInt32, parameters.population_size * parameters.generational_overlap_ratio)

        newcomers = Vector{Genotype}

        for _ in 1:to_replace_count
            contestants = StatsBase.sample(reproduction_set, β, replace=false)
            winner = get_best(manager.fitness_function, contestants)

            push!(newcomers, winner)
            deleteat!(reproduction_set, findall(x -> x == winner, reproduction_set))
        end

        newcomers
    end
end

### end SELECTIONS


### MATCHMAKING

random_matchmaking(population) = Random.shuffle(population) |> Consecutive(2) |> collect

### end MATCHMAKING


### WORK EVALUATORS

generation_count_evaluator(max_count::Int) = (state::GaManagerState) -> state.generation_count < max_count

### end WORK EVALUATORS


### MODIFICATION FRAMEWORK

modified_operator(modifier, operator) = modifier ∘ operator

fix_coloring(graph) = coloring -> begin
    fixed_coloring = copy(coloring)

    while true
        maybe_problematic_vertex = most_problematic_vertex(graph, fixed_coloring)
    end

    fixed_coloring
end

function most_problematic_vertex(graph, coloring)
    problem_table = Dict{Int, Int}()

    for edge in Graphs.edges(graph)
        vertex1 = Graphs.src(edge)
        vertex2 = Graphs.dst(edge)

        if coloring[vertex1] == coloring[vertex2]
            report_problem!(problem_table, vertex1)
            report_problem!(problem_table, vertex2)
        end
    end

    foldl(
        Filter(edge -> coloring[Graphs.src(edge)] == coloring[Graphs.dst(edge)]),
        Graphs.edges(graph);
        init=...
    ) do ...
        ...
    end
end

function report_problem!(problem_table, vertex)
    if !haskey(problem_table, vertex)
        problem_table[vertex] = 0
    end

    problem_table[vertex] += 1
end

### end MODIFICATION FRAMEWORK
