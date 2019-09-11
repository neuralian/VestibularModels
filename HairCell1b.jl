using Makie
using AbstractPlotting
using Printf
using Colors

using Distributions

#scene = Scene()
kᵦ = 1.38e-23  # Boltzmann constant J/K or m^2 kg ^-2 K^-1
T  = 300.      # temperature K
z  = 40.e-15   # Gating force 40 fN (Howard, Roberts & Hudspeth 1988)
d  = 3.5e-9    # Gate swing distance 3.5nm
pᵣ = 0.15      # resting/spontaneous open state probability
Nch = 48       # number of gating channels
pRange = 1e-7  # range of probabilities to plot (pRange, 1-pRange)

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
scene = lines(x,  p₀(x*xScale), title = "Hair cell gating",
             linewidth =4,
             color = :darkcyan,
             leg = false
        )
axis = scene[Axis]
 axis[:names][:axisnames] =
 ( "Bundle deflection /nm","Open State Probability")



# maximum sensitivity Δp₀ per nm
dx = 1e-9   # 1nm
Smax = (p₀(x₀+dx)-p₀(x₀-dx))/(2.0*dx)  # = slope at x₀
Λ2 = 1.0/(2.0*Smax) # half-space constant
x1 = (x₀ .+ collect((-nPts):(nPts))/nPts*Λ2)/xScale
lines!(x1,  .5 .+ Smax*(x1.-x₀/xScale)*xScale, color = :salmon)

# sensitivity at resting position
Srest = (p₀(dx)-p₀(-dx))/(2.0*dx)  # = slope at x₀
D = pᵣ/Srest
x2 = collect((-nPts/3):(nPts))/(nPts/3)*D/xScale
lines!(x2,  pᵣ .+ Srest*x2*xScale, color = :orange4)
 #annotation = (100, .125,
 #text(@sprintf("ΔS = %.2f", Smax/Srest),10,:left)))

# Shannon entropy of gate states
Hmax = entropy(Binomial(Nch,.5), 2.0)
H(p) = entropy(Binomial(Nch,p),2.0)/Hmax
lines!(x, map(H,p₀(x*xScale)), color=:darkgoldenrod3)


function drawHairCell(x0,y0, state)


  dx = 50.
  dy = .04

scatter!([x0],[y0],
  marker=:hexagon,
  markersize = 32,
  color = :purple,
  strokecolor =:black,
  strokewidth=.1)


x = zeros(48)
y = zeros(48)

# (x,y) coordinates of stereocilia
# 5 columns of 6
# centre + 2 on each side
for i in 1:6
  x[i] = x0-i*dx; y[i] = y0;
  x[6+i] = x0-i*dx + dx/2.0; y[6+i]=y0+dy
  x[12+i] = x0-i*dx + dx/2.0; y[12+i]=y0-dy
  x[18+i] = x0 - i*dx; y[18+i] = y0 + 2.0*dy
  x[24+i] = x0 - i*dx; y[24+i] = y0 - 2.0*dy
end
# two columns of 5 (one each side)
for i in 1:5
  x[30+i] = x0 - i*dx - dx/2.0; y[30+i] = y0 + 3.0*dy
  x[35+i] = x0 - i*dx - dx/2.0; y[35+i] = y0 - 3.0*dy
end
# ...and two columns of 4
for i in 1:4
  x[40+i] = x0 - (i+1)*dx; y[40+i] = y0 + 4.0*dy
  x[44+i] = x0 - (i+1)*dx; y[44+i] = y0 - 4.0*dy
end

# colours
c = [state[i] ? :gold1 : :dodgerblue1 for i in 1:48]
scatter!(x,y,
      marker=:circle,
      markersize = 32,
      color = c,
      strokewidth = .5,
      strokecolor=:black)

scene[end]  # return handle to hair cell bundle
end

# draw hair cell (resting state)
HC_handle = drawHairCell(-200., .75, rand(48).<pᵣ)

# draw kinocillium deflection icon

s1 = slider(LinRange(-100.0, 400.0, 100), raw = true, camera = campixel!, start = 0.3)

kx = lift(s1[end][:value]) do x
       x
end
scatter!(scene, [kx, kx],[0.5, p₀(kx[]*xScale)], marker = :hexagon,
    color = RGBA(.5,0.,.5,.5),
    markersize = 36, strokewidth = 1, strokecolor = :black)
Kc_handle = scene[end]
  xstep = 1.


# kx = lift(end][:value]) do v
#      map(LinRange(0, 2pi, 100))
#    end

RecordEvents(hbox(scene, s1, parent = Scene(resolution = (800, 600))),
    gateState = rand(48).<p₀(kx[]*xScale),
"output")

# record(scene, "haircell.mp4", 1:500) do i
#   Δx = x00 + i*xstep
#   p = p₀(Δx*xScale)
#   gateState = rand(48).<p
#   HC_handle[:color] = [gateState[i] ? :gold1 : :dodgerblue1 for i in 1:48]
#   Kc_handle[1] = [Δx, Δx]
#   Kc_handle[2] = [.5, p]
# end
