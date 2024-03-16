### CROSSOVERS

function multipoint(point_count::Int)
    (parent1::Genotype, parent2::Genotype) -> begin
        genotype_length = length(parent1)
        points = StatsBase.sample(1:(genotype_length - 1), point_count, replace=false, ordered=true)

        child1 = multipoint_core_operation(parent1, parent2, points)
        child2 = multipoint_core_operation(parent2, parent1, points)

        child1, child2
    end
end

function multipoint_core_operation(parent1::Genotype, parent2::Genotype, points::Vector{Int})
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

# function gene_mutation(genotype)
#     genotype_length = length(genotype)
#     mutant = copy(genotype)

#     gene_to_mutate = rand(1:genotype_length)
#     @inbounds mutant[gene_to_mutate] = (genotype_length - 1) - mutant[gene_to_mutate]

#     mutant
# end

# function swapping_mutation(genotype)
#     genotype_length = length(genotype)
#     mutant = copy(genotype)

#     first = rand(1:genotype_length)
#     second = rand(1:(genotype_length - 1))

#     if second < first
#         @inbounds mutant[first], mutant[second] = mutant[second], mutant[first]
#     else
#         @inbounds mutant[first], mutant[second + 1] = mutant[second + 1], mutant[first]
#     end

#     mutant
# end

full_mutation(genotype::Genotype) = (length(genotype) - 1) .- genotype

### end MUTATIONS


### SELECTIONS

function β_tournament(β::Int)
    function tournament(reproduction_set::Population, manager::GaManager)
        parameters = manager.iteration_settings.parameters
        to_replace_count = round(UInt32, parameters.population_size * parameters.generational_overlap_ratio)

        newcomers = Genotype[]

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

random_matchmaking(population::Population) = Random.shuffle(population) |> Consecutive(2) |> collect

### end MATCHMAKING


### WORK EVALUATORS

generation_count_evaluator(max_count::Int) = (state::GaManagerState) -> state.generation_count < max_count

### end WORK EVALUATORS


### MODIFICATION FRAMEWORK

modified_operator(modifier, operator) = modifier ∘ operator

function fix_coloring(graph::Graphs.AbstractGraph)
    fixer! = fix_coloring!(graph)
    coloring -> fixer!(copy(coloring))
end

fix_coloring!(graph::Graphs.AbstractGraph) = coloring -> begin
    while true
        problematic_vertex = most_problematic_vertex(graph, coloring)
        if isnothing(problematic_vertex)
            break
        end

        coloring[problematic_vertex] = smallest_color(graph, problematic_vertex, coloring)
    end

    coloring
end

function most_problematic_vertex(graph::Graphs.AbstractGraph, coloring)
    problem_table = Dict{Int, Int}()

    for edge in Graphs.edges(graph)
        vertex1 = Graphs.src(edge)
        vertex2 = Graphs.dst(edge)

        if coloring[vertex1] == coloring[vertex2]
            report_problem!(problem_table, vertex1)
            report_problem!(problem_table, vertex2)
        end
    end

    problematic_vertex = dict_key_by_max_value(problem_table)
    if problem_table[problematic_vertex] == 0
        nothing
    end

    problematic_vertex
end

function report_problem!(problem_table, vertex)
    if !haskey(problem_table, vertex)
        problem_table[vertex] = 0
    end

    problem_table[vertex] += 1
end

function dict_key_by_max_value(dict)
    maxkey, maxvalue = next(dict, start(dict))[1]

    for (key, value) in dict
        if value > maxvalue
            maxkey = key
            maxvalue = value
        end
    end

    maxkey
end

### end MODIFICATION FRAMEWORK
