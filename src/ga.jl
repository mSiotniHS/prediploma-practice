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

const Genotype = Vector{UInt16}
const Population = AbstractVector{Genotype}

struct GaManager
    iteration_settings::GaSettings
    fitness_function
    work_evaluator
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

function perform_selection!(population, reproduction_set, manager::GaManager)
    newcomers = manager.iteration_settings.operators.selection(reproduction_set, manager)
    Random.shuffle!(population)
    population[1:length(newcomers)] = newcomers
end

function run_iteration!(population::AbstractVector{Genotype}, manager::GaManager)
    parents = manager.iteration_settings.operators.matchmaking(population)
    children = perform_crossover(parents, manager.iteration_settings)

    if isempty(children)
        return population
    end

    mutants = mutate(children, manager.iteration_settings)

    reproduction_set = [children; mutants]

    perform_selection!(population, reproduction_set, manager)
end

function initialize_manager_state(manager::GaManager, population_generator)
    GaManagerState(population_generator(manager.iteration_settings.parameters.population_size), 0)
end

function find_solution(manager::GaManager, population_generator)
    state = initialize_manager_state(manager, population_generator)

    while manager.work_evaluator(state)
        run_iteration!(state.population, manager)
        state.generation_count += 1
    end

    get_best(manager.fitness_function, state.population)
end

get_best = minimum

population_generator(generator) = count -> map(1:count, _ -> generator())
