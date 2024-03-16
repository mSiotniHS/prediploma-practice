using DrWatson, Test
@quickactivate "vkr"

include(srcdir("vkr.jl"))

@testset "Operator testing" begin
    @testset "Crossover testing" begin
        @testset "Multipoint testing" begin
            @testset "Multipoint core operation behaves as expected" begin
                @test  [1, 0, 0, 1, 1] == multipoint_core_operation(
                    [1, 1, 1, 1, 1],
                    [0, 0, 0, 0, 0],
                    [1, 3]
                )

                @test [1, 0, 0, 0, 0] == multipoint_core_operation(
                    [1, 1, 1, 1, 1],
                    [0, 0, 0, 0, 0],
                    [1]
                )

                @test [1, 0, 1, 0, 0] == multipoint_core_operation(
                    [1, 1, 1, 1, 1],
                    [0, 0, 0, 0, 0],
                    [1, 2, 3]
                )
            end

            @testset "Multipoint random point generation behaves as expected $i" for i in 1:3
                points = StatsBase.sample(1:5, 3, replace=false, ordered=true)

                @test !isempty(points)
                @test issorted(points)
                @test points |> unique |> length == points |> length
                @test all(point -> 1 <= point <= 5, points)
            end
        end
    end

    @testset "Mutation testing" begin
        # @testset "Gene mutation testing $i" for i in 1:5
        #     genotype = [0, 1, 2, 3, 4]
        #     mutant = gene_mutation(genotype)

        #     @test genotype == [0, 1, 2, 3, 4]  # no changes
            
        #     difference = genotype - mutant

        #     one_gene_changed = difference |> filter(x -> x == 0) |> count == 4 && difference |> filter(x -> x != 0) |> count == 1
        #     its_value_is_in_range = 0 <= mutant[ difference |> findfirst(x -> x != 0) ] <= 4
        #     no_genes_changed = difference |> filter(x -> x == 0) |> count == 5
        #     @test (one_gene_changed && its_value_is_in_range) || no_genes_changed
        # end

        @testset "Full mutation testing" begin
            @test full_mutation([0, 1, 2, 3, 4]) == [4, 3, 2, 1, 0]
            @test full_mutation([0, 1, 2, 0, 1]) == [4, 3, 2, 4, 3]
        end
    end

    @testset "Matchmaking testing" begin
        @testset "Random matchmaking testing" begin
            population = [
                [0, 0],
                [1, 1],
                [2, 2],
                [3, 3],
                [4, 4],
                [5, 5]
            ]

            matches = random_matchmaking(population)

            @test length(matches) == 3                                            # total of 3 matches
            @test all(match -> length(match) == 2, matches)                       # matches by 2
            @test Iterators.flatten(matches) |> collect |> unique |> length == 6  # no repetitions
        end
    end

    @testset "Selection testing" begin
        @testset "β-tournament testing" begin
            reproduction_set = [
                [0, 0],
                [1, 1],
                [1, 0]
            ]
            newcomers = Vector{Int}[]
            contestant_idxs = [1, 3]
            fitness_function = sum
            run_tournament!(reproduction_set, newcomers, contestant_idxs, fitness_function)
            @test newcomers == [[0, 0]]
        end
    end

    @testset "Work evaluators" begin
        @testset "Generation count evaluator" begin
            n = 1

            max_n = generation_count_evaluator(n)
            run_count = 0
            state = GaManagerState(Genotype[], 0)

            while max_n(state)
                state.generation_count += 1
                run_count += 1
            end

            @assert run_count == n
        end
    end
end


@testset "Graph coloring tests" begin
    @testset "Criterion testing" begin
        @testset "color_count testing" begin
            @test color_count([0, 1, 2, 1]) == 3
            @test color_count([0, 1, 1, 1]) == 2
            @test color_count([0, 0, 1, 3]) == 3
        end
    end

    @testset "Population generation testing" begin
        @testset "smallest_color testing" begin
            graph = Graphs.SimpleGraph()
            Graphs.add_vertices!(graph, 4)
            Graphs.add_edge!(graph, 4, 1)
            Graphs.add_edge!(graph, 4, 2)
            Graphs.add_edge!(graph, 4, 3)
            coloring = [0, 1, nothing, nothing]
            @test smallest_color(graph, 4, coloring) == 2
        end

        @testset "greedy_coloring" begin
            graph = Graphs.SimpleGraph()
            Graphs.add_vertices!(graph, 4)
            Graphs.add_edge!(graph, 1, 2)
            Graphs.add_edge!(graph, 1, 3)
            Graphs.add_edge!(graph, 2, 3)
            Graphs.add_edge!(graph, 3, 4)

            @test greedy_coloring(_ -> [3, 2, 1, 4])(graph) == [2, 1, 0, 1]
        end
    end
end


@testset "GA testing" begin
    @testset "Mutation procedure testing" begin
        children = [
            [0, 0],
            [1, 0],
            [1, 0],
            [1, 1],
            [0, 1],
            [0, 0]
        ]
        mutation = x -> x |> Map(i -> i + 1) |> collect
        settings = GaSettings(
            IterationOperators(
                identity,
                identity,
                mutation,
                identity
            ),
            GaParameters(
                0,
                -0.0,
                1.0,
                -0.0
            )
        )

        mutants = mutate(children, settings)
        @test length(mutants) == 6
        @test mutants == [
            [1, 1],
            [2, 1],
            [2, 1],
            [2, 2],
            [1, 2],
            [1, 1]
        ]
    end

    @testset "Crossover procedure testing" begin
        population = [
            [0, 0],
            [1, 0],
            [1, 0],
            [1, 1],
            [0, 1],
            [0, 0]
        ]

        settings = GaSettings(
            IterationOperators(
                identity,
                (x, y) -> (x, y),
                identity,
                identity
            ),
            GaParameters(
                0,
                1.0,
                -0.0,
                -0.0
            )
        )

        children = perform_crossover(population, settings)
        @info children

        @test length(children) == 6
        @test children == [
            [0, 0],
            [1, 0],
            [1, 0],
            [1, 1],
            [0, 1],
            [0, 0]
        ]
    end
end
