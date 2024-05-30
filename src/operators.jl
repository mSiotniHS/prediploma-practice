#region CROSSOVERS

function multipoint(point_count::Int)
    (parent1::AbstractVector{Int}, parent2::AbstractVector{Int}) -> begin
        genotype_length = length(parent1)
        points = StatsBase.sample(1:(genotype_length - 1), point_count, replace=false, ordered=true)

        child1 = multipoint_core_operation(parent1, parent2, points)
        child2 = multipoint_core_operation(parent2, parent1, points)

        child1, child2
    end
end

function multipoint_core_operation(parent1::AbstractVector{Int}, parent2::AbstractVector{Int}, points::Vector{Int})
    child = similar(parent1)
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

spx = multipoint(1)

function shuffle(parent1::Genotype, parent2::Genotype)
    permutation = Random.randperm(length(parent1))
    tmp1, tmp2 = spx(view(parent1, permutation), view(parent2, permutation))

    child1, child2 = similar(tmp1), similar(tmp2)
    for (i, j) in enumerate(permutation)
        child1[j] = tmp1[i]
        child2[j] = tmp2[i]
    end

    child1, child2
end

function uniform(p1::Genotype, p2::Genotype)
    i = rand(Bool, length(p1))
    j = .!i

    c1 = p1 .* i .+ p2 .* j
    c2 = p1 .* j .+ p2 .* i

    c1, c2
end

#endregion


#region MUTATIONS

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

#endregion


#region SELECTIONS

function β_tournament(β::Int)
    function tournament(reproduction_set::Population, manager::GaManager)
        parameters = manager.iteration_settings.parameters
        to_replace_count = round(UInt32, parameters.population_size * parameters.generational_overlap_ratio)

        newcomers = Genotype[]

        for _ in 1:to_replace_count
            contestant_count = min(β, length(reproduction_set))
            if contestant_count == 0
                break
            end

            contestant_idxs = StatsBase.sample(1:length(reproduction_set), contestant_count, replace=false)
            run_tournament!(reproduction_set, newcomers, contestant_idxs, manager.fitness_function)
        end

        newcomers
    end
end

function run_tournament!(reproduction_set::Population, newcomers::Population, contestant_idxs, fitness_function)
    winner_idx = get_best(x -> fitness_function(reproduction_set[x]), contestant_idxs)

    push!(newcomers, reproduction_set[winner_idx])
    deleteat!(reproduction_set, winner_idx)
end

#endregion


#region MATCHMAKING

random_matchmaking(population::Population) = Random.shuffle(population) |> Consecutive(2) |> collect

#endregion


#region WORK EVALUATORS

generation_count_evaluator(max_count::Int) = (state::GaManagerState) -> state.generation_count < max_count

function no_progress_evaluator(max_no_progress_count::Int, fitness_func)
    last_best_fitness = typemax(Int)
    no_progress_count = 0

    return function f(state::GaManagerState)
        best_fitness = minimum(fitness_func, state.population)

        if best_fitness < last_best_fitness
            last_best_fitness = best_fitness
            no_progress_count = 0
            return true
        end

        no_progress_count += 1
        return no_progress_count < max_no_progress_count
    end
end

function every_nth_check_evaluator(check_iteration::Int, fitness_func)
    last_best_fitness = typemax(Int)
    iterations_from_last_check = 0

    return function f(state::GaManagerState)
        if iterations_from_last_check < check_iteration
            iterations_from_last_check += 1
            return true
        end

        best_fitness = minimum(fitness_func, state.population)
        if best_fitness < last_best_fitness
            last_best_fitness = best_fitness
            iterations_from_last_check = 1
            return true
        end

        return false
    end
end

#endregion


### MODIFICATION FRAMEWORK

function fix_coloring(graph::Graphs.AbstractGraph)
    fixer! = fix_coloring!(graph)
    return coloring -> fixer!(copy(coloring))
end

function fix_coloring!(graph::Graphs.AbstractGraph) 
    edges = collect(Graphs.edges(graph))

    return function tmp(coloring)
        while true
            problematic_vertex = most_problematic_vertex(edges, coloring)
            if isnothing(problematic_vertex)
                break
            end

            @info "There is still a problematic vertex"

            coloring[problematic_vertex] = smallest_color(graph, problematic_vertex, coloring)
        end

        return coloring
    end
end

function most_problematic_vertex(graph_edges, coloring)
    problem_table = Dict{Int, Int}()

    for i in eachindex(graph_edges)
        edge = graph_edges[i]
        vertex1 = Graphs.src(edge)
        vertex2 = Graphs.dst(edge)

        if coloring[vertex1] == coloring[vertex2]
            report_problem!(problem_table, vertex1)
            report_problem!(problem_table, vertex2)
        end
    end

    @info "Current problems"  problem_table

    if isempty(problem_table)
        return nothing
    end

    problematic_vertex = dict_key_by_max_value(problem_table)
    if problem_table[problematic_vertex] == 0
        return nothing
    end

    return problematic_vertex
end

function report_problem!(problem_table, vertex)
    if !haskey(problem_table, vertex)
        problem_table[vertex] = 0
    end

    problem_table[vertex] += 1
end

dict_key_by_max_value(d) = collect(keys(d))[argmax(collect(values(d)))]

### end MODIFICATION FRAMEWORK
