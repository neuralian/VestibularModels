using Plots
pyplot()
using Printf

kᵦ = 1.38e-23  # Boltzmann constant J/K or m^2 kg ^-2 K^-1
T  = 300.      # temperature K
z  = 40.e-15   # Gating force 40 fN (Howard, Roberts & Hudspeth 1988)
d  = 3.5e-9    # Gate swing distance 3.5nm
pᵣ = 0.15      # resting/spontaneous open state probability

pRange = 1e-6  # range of probabilities to plot (pRange, 1-pRange)

# solve p₀(x₀)= 1/2 (deflection when open state prob = 1/2)
x₀ =  kᵦ*T*log( (1-pᵣ)/pᵣ)/z

# solve p₀(xRange)= pRange to find plot range
xRange =  kᵦ*T*log( (1-pRange)/pRange)/z

# open state probability as a function of bundle deflection
p₀(x) = 1.0./(1.0 .+ exp.(-z*(x.-x₀)/(kᵦ*T)))

# plot
nPts = 100.
xScale = 1e-9    # x-axis in nm
x = (x₀ .+ collect((-nPts/2.):(nPts/2.))/nPts*xRange)/xScale
p1 = plot(x,  p₀(x*xScale), title = "Hair cell gating",
             leg = false,
             ylabel = "Open State Probability",
             xlabel = "Bundle deflection /nm",
             size = (400,300))

# maximum sensitivity Δp₀ per nm
dx = 1e-9   # 1nm
Smax = (p₀(x₀+dx)-p₀(x₀-dx))/(2.0*dx)  # = slope at x₀
Λ2 = 1.0/(2.0*Smax) # half-space constant
x1 = (x₀ .+ collect((-nPts):(nPts))/nPts*Λ2)/xScale
plot!(x1,  .5 .+ Smax*(x1.-x₀/xScale)*xScale, line = :dash)

# sensitivity at resting position
Srest = (p₀(dx)-p₀(-dx))/(2.0*dx)  # = slope at x₀
D = pᵣ/Srest
x2 = collect((-nPts):(nPts))/nPts*D/xScale
plot!(x2,  pᵣ .+ Srest*x2*xScale, line = :dash,
 annotation = (200, .25,
 text(@sprintf("Sensitivity ratio: %.2f", Srest/Smax),10,:left)))

display(p1)
#savefig("HairCellGating")

function drawHairCell(x,y, state)

  dx = 70.
  dy = .05

plot!([x],[y],
  markershape=:hexagon,
  markersize = 10,
  markercolor = :purple,
  markerstrokewidth=.5)

function drawStereocillium(x,y, state)
   if state==1
     colour = :yellow
   else
     colour = :green
   end
    plot!([x],[y],
      markershape=:circle,
      markersize = 8,
      markercolor = colour,
      markerstrokewidth=.5)
end

for i in 1:6
  drawStereocillium(x-i*dx,y, state[i])
  drawStereocillium(x-i*dx + dx/2,y+dy, state[6+i])
  drawStereocillium(x-i*dx + dx/2,y-dy, state[12+i])
end

end

drawHairCell(0, .5, convert(Array{Int64},rand(18).<pᵣ))

display(p1)
