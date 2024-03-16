using DrWatson
@quickactivate "vkr"
include(srcdir("vkr.jl"))

sq = opcompose(Map(x -> x^2), tcollect)

a = [1, 2, 3, 4, 5]

@info a |> sq
