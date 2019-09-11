using Makie
using AbstractPlotting

scene=Scene()
 N = 25
 r = [(rand(3, 2) .- 0.5) .* 25 for i = 1:N]
scatter!([0.;1.], [0.; 1.], markersize = 2, color = :blue)
s1 = scene[end]
scatter!(r[1][:, 1], r[1][:, 2], markersize = 1,
         color =[:red, :red, :red],
         limits = FRect(-25/2, -25/2, 25, 25))
 s2 = scene[end] # last plot in scene
 display(scene)
 record(scene, "output.mp4", 1:25) do i
        s1[1] = rand(2)
        s1[2] = rand(2)*5
        s2[:color] = [rand(1)[]<.25 ? :red : :green for j in 1:3]

end
