struct GaParameters
    population_size::UInt32
    crossover_rate::Float64
    mutation_rate::Float64
    generational_overlap_ratio::Float64
end

struct IterationOperators{T1, T2, T3, T4}
    matchmaking::T1
    crossover::T2
    mutation::T3
    selection::T4
end

struct GaSettings
    operators::IterationOperators
    parameters::GaParameters
end

const Genotype = Vector{Int}
const Population = Vector{Genotype}

struct GaManager{T1, T2}
    iteration_settings::GaSettings
    fitness_function::T1
    work_evaluator::T2
end

mutable struct GaManagerState
    population::Population
    generation_count::Int
end

mutate(children::Population, settings::GaSettings) =
    children |>
        Filter(_ -> rand() < settings.parameters.mutation_rate) |>
        Map(settings.operators.mutation) |>
        tcollect

perform_crossover(parents, settings::GaSettings) =
    parents |>
        Filter(_ -> rand() < settings.parameters.crossover_rate) |>
        MapCat(pair -> settings.operators.crossover(pair[1], pair[2])) |>
        tcollect

function perform_selection!(population::Population, reproduction_set::Population, manager::GaManager)
    newcomers = manager.iteration_settings.operators.selection(reproduction_set, manager)
    Random.shuffle!(population)
    population[1:length(newcomers)] = newcomers
end

function run_iteration!(population::Population, manager::GaManager)
    parents = manager.iteration_settings.operators.matchmaking(population)
    children = perform_crossover(parents, manager.iteration_settings)

    if isempty(children)
        return population
    end

    mutants = mutate(children, manager.iteration_settings)

    reproduction_set = if isempty(mutants)
        children
    else
        [children; mutants]
    end

    perform_selection!(population, reproduction_set, manager)
end

function initialize_manager_state(manager::GaManager, population_generator)
    GaManagerState(population_generator(manager.iteration_settings.parameters.population_size), 0)
end

function find_solution(manager::GaManager, population_generator)
    state = initialize_manager_state(manager, population_generator)

    to_fitnesses = opcompose(Map(manager.fitness_function), tcollect)

    history = Vector{Int}[]
    push!(history, state.population |> to_fitnesses)

    while manager.work_evaluator(state)
        run_iteration!(state.population, manager)
        state.generation_count += 1

        push!(history, state.population |> to_fitnesses)
    end

    history
end

population_generator(generator) = (count) -> 1:count |> Map(_ -> generator()) |> tcollect
