using DrWatson
@quickactivate "vkr"
include(srcdir("vkr.jl"))

allparams = Dict(
    :crossover => ["multipoint_2"],
    :graph => Dict(
        :vertex_count => [200],
        :ρ => [0.5],
        :count => collect(1:75)
    ),
    :run => collect(1:50)
)

allparams[:graph] = dict_list(allparams[:graph])
dicts = dict_list(allparams)

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

multipoint_2 = multipoint(2)
tournament_3 = β_tournament(3)
generation_count_evaluator_75 = generation_count_evaluator(75)
graph_coloring_method = random_coloring

loadgraph(graph_dict) = Graphs.loadgraph(joinpath("data\\graphs\\vertex_count", savename(graph_dict, "txt")))

function make_ga(dict::Dict)
    @unpack graph, crossover = dict

    crossover_op = if crossover == "multipoint_2"
        multipoint_2
    elseif crossover == "shuffle"
        shuffle
    elseif crossover == "uniform"
        uniform
    end

    graph_obj = loadgraph(dict[:graph])

    run_ga(graph_obj, crossover_op)
end

function run_ga(graph, crossover)
    f = color_count_with_penalty(graph; weight=2)
    @Memoize.memoize function fitness(coloring::Coloring)
        f(coloring)
    end

    manager = GaManager(
        GaSettings(
            IterationOperators(
                random_matchmaking,
                crossover,
                full_mutation,
                tournament_3
            ),
            GaParameters(
                Graphs.nv(graph),
                0.9,
                0.1,
                0.5
            )
        ),
        fitness,
        generation_count_evaluator_75
    )

    generator() = graph_coloring_method(graph)
    pg = population_generator(generator)

    find_solution(manager, pg)
    # @profview find_solution(manager, pg)
    # @profview find_solution(manager, pg)
end

DrWatson._wsave(filename, data::Tuple{Vector{Vector{Int}}, Vector{Population}}) = open(filename, "w") do file
    run_info = Dict{Symbol, Any}()
    run_info[:history] = Vector{Dict{Symbol, Any}}()

    fitnesses, population_25ths = data

    write(file, "NEW\n")

    for i in eachindex(fitnesses)
        iteration_fitnesses = fitnesses[i]
        write(file, join(iteration_fitnesses |> Map(string), ","))
        write(file, "\n")
    end

    write(file, "---\n")

    for i in eachindex(population_25ths)
        population = population_25ths[i]

        for j in eachindex(population)
            genotype = population[j]
            write(file, join(genotype |> Map(string), ","))
            write(file, "\n")
        end

        write(file, "-\n")
    end
end


function main()
    Threads.@threads for i in eachindex(collect(keys(dicts)))
        flatten = rec_flatten_dict(dicts[i])
        data_dir = datadir("simulations/vertex_count", savename(flatten, "txt"))
    
        if !isfile(data_dir)
            @info "started!"
            @time result = make_ga(dicts[i])
            safesave(data_dir, result)
        end
    end
end

main()
