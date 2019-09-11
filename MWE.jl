using Makie
using AbstractPlotting
using Colors


x00=-5.
gateState = false
xRange =  10

#  deflection
p₀(x) = x/2

# plot
nPts = 100.
x = (x₀ .+ collect((-nPts/2.):(nPts/2.))/nPts*xRange)/xScale
scene = lines(x,  p₀(x),
             linewidth =4,
             color = :darkcyan,
             leg = false
        )
axis = scene[Axis]
 axis[:names][:axisnames] =
 ( "x","y")


HC_handle = scatter!([-4], [2], marker=:circle,
          markersize = .5, color = :red)[end]

s1 = slider(LinRange(-5.0, 5.0, 101),
      raw = true, camera = campixel!, start = -5.0)

kx = s1[end][:value]

scatter!(scene, [kx[]; kx[]],[0.5; p₀(kx[])], marker = :hexagon,
    color = RGBA(.5,0.,.5,.5),
    markersize = .35, strokewidth = 1, strokecolor = :black)
Kc_handle = scene[end]

record(hbox(scene, s1, parent = Scene(resolution = (800, 600))),
   "gate.mp4", 1:200) do i
    Δx = x00 + 0.05*i
    p = p₀(Δx)
    gateState = rand(1)[]<(p + 2.5)/5
    HC_handle[:color] = gateState ? :gold1 : :dodgerblue1
    Kc_handle[1] = [Δx, Δx]
    Kc_handle[2] = [0, p]
end
