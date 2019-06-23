# Interactive animation of vestibular hair cell transduction channel
# gating as a function of kinocillium deflection
# Mike Paulin University of Otago 2019
#


using Makie
using AbstractPlotting
using Colors
using Distributions
using Revise

# set thisScreen = big- or small- depending on
# how much screen real estate you have (or want the window to occupy)
bigScreen = (1600, 600)
smallScreen = (800, 400)
thisScreen = bigScreen


kᵦ = 1.38e-23  # Boltzmann constant J/K or m^2 kg ^-2 K^-1
T  = 300.      # temperature K
z  = 40.e-15   # Gating force 40 fN (Howard, Roberts & Hudspeth 1988)
d  = 3.5e-9    # Gate swing distance 3.5nm
pᵣ = 0.15      # resting/spontaneous open state probability
Nch = 48       # number of gating channels
pRange = 1e-6  # range of probabilities to plot (pRange, 1-pRange)
hairScale = 0.05 # scale deflection from plot to gate-state animation
dt = 1e-4        # 100 microsecond time steps

# solve p₀(x₀)= 1/2 (deflection when open state prob = 1/2)
x₀ =  kᵦ*T*log( (1-pᵣ)/pᵣ)/z

# solve p₀(xRange)= pRange to find plot range
xRange =  kᵦ*T*log( (1-pRange)/pRange)/z

# open state probability as a function of bundle deflection
p₀(x) = 1.0./(1.0 .+ exp.(-z*(x.-x₀)/(kᵦ*T)))

# plot
animationPane = Scene(limits=FRect(-600., 0., 1600., 1.))
nPts = 100.
xScale = 1e-9    # x-axis in nm
x = (x₀ .+ collect((-nPts/2.):(nPts/2.))/nPts*xRange)/xScale
 lines!(animationPane, x,  p₀(x*xScale), title = "Hair cell gating",
             linewidth =4,
             color = :darkcyan,
             leg = false
        )
axis = animationPane[Axis]
 axis[:names][:axisnames] =
 ( "Bundle deflection /nm","Open State Probability")

plotPanel = Scene(limits=FRect(0,0., 1000.,1000.))
t = 1:1000
w = 0.17 .+ randn(size(t))
plot!(plotPanel,t, w  , xlim = (0, 1000), ylim = (0, 1),
   scale_plot = false,
   show_axis = false,
   color = :purple)
D = plotPanel[end]

function drawHairCell(panel, x0,y0, state)

  dx = 48.5
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


# create display windo
S = vbox(plotPanel, hbox(s1, animationPane, sizes = [.1, .9]),
     sizes = [.5, .5], parent = Scene(resolution = thisScreen));


# Brownian motion
# The let-end block allows local variables to be defined and initialized
# that are visible in the while-end block
let
  wobble = 0.0        # kinocillium Brownian deflection
  Q =4.e3       # thermal noise power
  τₖ = 2.0e-3         # bundle time constant 2ms (500Hz roll-off)
  α = exp(-dt/τₖ)      # difference eqn coeff for time const τₖ
  σₖ = sqrt(Q*dt/(1-α^2))  # noise rms power
  #println(σₖ)



# animate gate states
# gates flicker open (yellow) and closed (blue)
@async while isopen(S) # run this block as parallel thread
                       # while scene (window) is open
                       # NB if you edit and re-run the script without
                       # closing the scene or re-starting Julia
                       # then this block continues to run ... you'll have
                       # two processes updating the scene! (and you can see it)

  # Brownian perturbation RMS 2nm
  # nb deflection is an Observable whose (observed) value is deflection[]
  # Similarly randn(1) is a 1-element array of random numbers
  #    but randn(1)[] (or randn(1)[1]) is a random number
  wobble = α*wobble + σₖ*randn(1)[]

  Δk = deflection[] + Float32(wobble)

  p = p₀(Δk*xScale)
  gateState = rand(48).<p
  HC_handle[:color] = [gateState[i] ? :gold1 : :dodgerblue1 for i in 1:48]

  KC_handle[1][] = [Point2f0(Δk*hairScale, 0.5), Point2f0(Δk, p)]

  dScale = .5
  push!(deleteat!(w,1),p*1000.)
  D[2] = w

  # change/comment out this delay
  # depending on the speed of your machine
  # (animation runs way too fast on the dev machine)
  sleep(.001)

  yield() # allow code below this block to run
          # while continuing to run this block
end

end

RecordEvents(S, "output")
