using Makie
using AbstractPlotting

 N = 10
 r = [(rand(3, 2) .- 0.5) .* 25 for i = 1:N]
 limits = FRect(-3, -2, 6, 4)
 scene = scatter([1.;2.;3.], [1.;1.;1.], markersize = .2, limits=limits )
 s1 = scene[end]
 lines!([0., 1.], [0., 1.], limits=limits )
 s2 = scene[end] # last plot in scene
 display(scene)

 record(scene, "output.mp4", 1:150) do t
     s1[1] = [1.;2.;3.]*sin(2.0*π*t/150)
     s1[2] = ones(3)*cos(2.0*π*t/150)
     c = rand(1)[]<.5 ? :red : :blue
     s2[:color] = c
     s2[1] = [0.0; sin(2.0*π*t/150)]
     s2[2] = [0.0; cos(2.0*π*t/150)]
end
