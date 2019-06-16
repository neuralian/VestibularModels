# Interactive animation of vestibular hair cell transduction channel
# gating as a function of kinocillium deflection
# Mike Paulin University of Otago 2019
#


using Makie
using AbstractPlotting
using Colors
using Distributions


kᵦ = 1.38e-23  # Boltzmann constant J/K or m^2 kg ^-2 K^-1
T  = 300.      # temperature K
z  = 40.e-15   # Gating force 40 fN (Howard, Roberts & Hudspeth 1988)
d  = 3.5e-9    # Gate swing distance 3.5nm
pᵣ = 0.15      # resting/spontaneous open state probability
Nch = 48       # number of gating channels
pRange = 1e-7  # range of probabilities to plot (pRange, 1-pRange)
hairScale = 0.05 # scale deflection from plot to gate-state animation

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
animationPane = lines(x,  p₀(x*xScale), title = "Hair cell gating",
             linewidth =4,
             color = :darkcyan,
             leg = false
        )
axis = animationPane[Axis]
 axis[:names][:axisnames] =
 ( "Bundle deflection /nm","Open State Probability")

deflectionPane = Scene(limits=FRect(0,-5, 1000,5))
plot!(deflectionPane,  randn(1000)*10., scale_plot = false,
   show_axis = false)
depolarizationPane =  Scene(limits=FRect(0,-5, 1000,5))
plot!(depolarizationPane,  randn(1000)*10., scale_plot = false,
   show_axis = false)

# # maximum sensitivity Δp₀ per nm
# dx = 1e-9   # 1nm
# Smax = (p₀(x₀+dx)-p₀(x₀-dx))/(2.0*dx)  # = slope at x₀
# Λ2 = 1.0/(2.0*Smax) # half-space constant
# x1 = (x₀ .+ collect((-nPts):(nPts))/nPts*Λ2)/xScale
# lines!(x1,  .5 .+ Smax*(x1.-x₀/xScale)*xScale, color = :salmon)

# # sensitivity at resting position
# Srest = (p₀(dx)-p₀(-dx))/(2.0*dx)  # = slope at x₀
# D = pᵣ/Srest
# x2 = collect((-nPts/3):(nPts))/(nPts/3)*D/xScale
# lines!(x2,  pᵣ .+ Srest*x2*xScale, color = :orange4)

# # Shannon entropy of gate states
# Hmax = entropy(Binomial(Nch,.5), 2.0)
# H(p) = entropy(Binomial(Nch,p),2.0)/Hmax
# lines!(x, map(H,p₀(x*xScale)), color=:darkgoldenrod3)

function drawHairCell(panel, x0,y0, state)

  dx = 45.
  dy = .04

  scatter!(panel, [x0],[y0],
    marker=:hexagon,
    markersize = 36,
    color =  RGBA(.5,0.,.5,.5),
    strokecolor =:black,
    strokewidth=.1)

  x = zeros(48)
  y = zeros(48)

  # (x,y) coordinates of stereocilia.
  # 5 columns of 6,   # centre + 2 on each side
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
  scatter!(panel, x,y,
        marker=:circle,
        markersize = 32,
        color = c,
        strokewidth = .5,
        strokecolor=:black)

  panel[end]  # return handle to hair cell bundle
end

# draw hair cell (resting state)
HC_handle = drawHairCell(animationPane, -0., .5, rand(48).<pᵣ)


# slider controls kinocillium deflection
s1 = slider(LinRange(x[1], x[end], 100),
        raw = true, camera = campixel!, start = 0.0)
deflection = s1[end][:value]



# draw kinocillium deflection indicators
scatter!(animationPane, [deflection[]*hairScale, x],
                [0.5, p₀(deflection[]*xScale)],
                marker = [:hexagon,:circle],
                color = RGBA(.5,0.,.5,1.0),
                markersize = [32, 24],
                strokewidth = 1,
                strokecolor = :black)
KC_handle = animationPane[end]  # Array{Point{2,Float32},1} coordinates




S = hbox(depolarizationPane, deflectionPane, animationPane, s1,
     sizes = [.1, .1, .7, .1], parent = Scene(resolution = (1000, 800)));

# animate gate states
# gates flicker open (yellow) and closed (blue)
@async while isopen(S) # run this block as parallel thread
                       # while scene (window) is open

  # random (Normal) Brownian perturbation to deflection, RMS 2nm
  # nb deflection is an Observable whose (observed) value is deflection[]
  # Similarly randn(1) is a 1-element array of random numbers
  #    and randn(1)[] (or randn(1)[1]) is a random number
  Δk = deflection[]+Float32(randn(1)[])*2.0

  p = p₀(Δk*xScale)
  gateState = rand(48).<p
  HC_handle[:color] = [gateState[i] ? :gold1 : :dodgerblue1 for i in 1:48]

  KC_handle[1][] = [Point2f0(Δk*hairScale, 0.5), Point2f0(Δk, p)]

  yield() # allow code below this block to run
          # while continuing to run this block
end

RecordEvents(S, "output")
