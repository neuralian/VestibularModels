using Makie
using AbstractPlotting

θ = Node(0.0)
clr = Node(:red)
c = :red

L = Node(10.)   # spring length
ψ = Node(.5)    # spring angle
limits = FRect(0, -5, 10, 10)
scene = Scene(limits=limits )
f = 5   # number of loops in spring
lines!(lift(λ-> (λ*(0.:.01:1.),sin.(2π*f*(0.:.01:1.))), L),   linewidth = 2)

 display(scene)

#  record(scene, "output.mp4", 1:360) do t
#      if (rand(1)[]<.1)
#         global  c = rand(1)[]<.5 ? :red : :blue
#      end
#      push!(θ, 2.0*π*t/360.)
#      push!(clr, c)
# end
