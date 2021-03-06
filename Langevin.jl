
begin
    using MCMC
    # using .MetropolisUpdate
    # using .UsersGuide
    using Distributions
    using Plots
    using StochasticDiffEq#, DifferentialEquations
    using LabelledArrays
    using BenchmarkTools
    gaussianD = Normal(0,1) # Generator for gaussian distributed random numbers
    save_path = "results/"
    save_date = findDate() # Save date for plot names
    save_folder = "plots/" # Where to store plots
end

# import Pkg; Pkg.activate("."); Pkg.instantiate()












#########################################
# Langevin simulation of AHO
#########################################

# Define physical parameters
# n_tau=16; β=8.; a=β/n_tau; m=1.; μ=1.; λ=0.;
phys_p = getAHO_L_param(16,8.,1.,1.,0.)
# Define simulation parameters
dt=0.001; n_burn=ceil(Int32,3/dt); n_skip=ceil(Int32,3/dt);
sim_p = getSim_L_param(1000,n_burn,n_skip,dt)

# Simulation giving configurations in matrix [N_total,N_tau]
res1 = Langevin_AHO(phys_p,sim_p,gaussianD)

# Analysis
PlotAC(res1,300)
# title!("Autocorrelation")
savefig("$(save_folder)$(save_date)_L_old_AC.png") # .pdf for pdf quality plot
PlotTPCF(res1)
PlotTPCFe!(0.5,1,1,16)
# title!("Two-point correlation")
savefig("$(save_folder)$(save_date)_L_old_TPCF.png")



# Simulation appending configurations to file "$(savename)"
    # For a new, clean simulation, delete the existing file

# Define physical parameters
# β=8.; n_tau=16; a=β/n_tau; m=1.; μ=1.; λ=0.;
phys_p = AHO_L_param(8.,16,1.,1.,0.)
# Define simulation parameters
dt=0.001; n_burn=3/dt; n_skip=3/dt;
sim_p = Sim_L_param(1000,n_burn,n_skip,dt)

save_name = "$(save_path)$(save_date)_L_old_simulation.csv"
Langevin_AHO(phys_p,sim_p,gaussianD,save_name)

# Analysis
PlotAC(save_name)   # save_name = name of file storing the results from simulation
# title!("Autocorrelation")
savefig("$(save_folder)$(save_date)_L_old_AC.png") # .pdf for pdf quality plot
PlotTPCF(save_name)
PlotTPCFe!(0.5,1,1,16)
# title!("Two-point correlation")
savefig("$(save_folder)$(save_date)_L_old_TPCF.png")












#########################################
# Complex Langevin simulation of Gaussian system
#########################################


# Define physical parameters
# μ = 1. + 0.2*im;
μ = exp(1*im*π/4)
phys_p = getGaussian_CL_param(μ)
# Define simulation parameters
dt=0.001; n_burn=3/dt; n_skip=3/dt;
sim_p = Sim_CL_param(1000,n_burn,n_skip,dt)

# Simulation giving configurations in matrix [N_total,N_tau]
a1 = ImplicitEM(theta = 1,symplectic=false)
a2 = ImplicitEM(theta = 0.5,symplectic=false)
a3 = EM()
a4 = SKenCarp()
a5 = DRI1()
# = ImplicitEM(theta = 0,symplectic=false)
res1 = CLangevin_Gauss(phys_p,sim_p,gaussianD)

begin # Analysis
    save_pre = "$(save_folder)$(save_date)_G_mu0.9"
    PlotAC(res1[1]) # Autocorrelation of real part
    savefig("$(save_pre)_AC.pdf")
    savefig("$(save_pre)_AC.png")
    
    scatter(res1[1],res1[2],xlabel="ϕ_r",ylabel="ϕ_i") # Scatter real against complex
    savefig("$(save_pre)_scatter.pdf")
    savefig("$(save_pre)_scatter.png")
    
    PlotProbDD(res1[1]) # Show probability distribution
    savefig("$(save_pre)_PDD.pdf")
    savefig("$(save_pre)_PDD.png")
    
    Err1(res1[1].^2)
end

x3_1 = []
begin
scatter([imag(1/μ)],[real(1/μ)],xlabel="ϕ_r",ylabel="ϕ_i",label="")
x3_2 = []
x3_3 = []
fig = 0
for i in [a1,a2,a3,a4,a5]
res1 = LangevinGaussSchem(phys_p,sim_p,i)
begin
    a = res1.u
    a
    x = Array{Complex}(undef,length(res1.u))
    for i =1:length(res1.u)
        x[i] = (res1.u[i][1] + im*res1.u[i][2])
    end
    # Err1(x)
    # x2 = Array{Complex}(undef,length(res1.u))
    x2 = x.^2
    res = Err1(x2)
    # y = imag(res[1])
    # println(res)
    if i == a1
        fig = scatter!([imag.(res[1])],[real.(res[1])],yerr=[real.(res[2])],label="ImplicitEM(θ=1)")#xerr=[imag.(res[1])],
    elseif i ==a2
        fig = scatter!([imag.(res[1])],[real.(res[1])],yerr=[real.(res[2])],label="ImplicitEM(θ=0.5)")#xerr=[imag.(res[1])],
    elseif i == a3
        fig = scatter!([imag.(res[1])],[real.(res[1])],yerr=[real.(res[2])],label="EM(θ=0.5)")#xerr=[imag.(res[1])],
    elseif i == a4
        fig = scatter!([imag.(res[1])],[real.(res[1])],yerr=[real.(res[2])],label="SKenCarp")#xerr=[imag.(res[1])],
    elseif i == a5
        fig = scatter!([imag.(res[1])],[real.(res[1])],yerr=[real.(res[2])],label="DRI1")#xerr=[imag.(res[1])],
    end
    display(fig)
end
end
end
x3_1
resulttime = [[4.056458],[3.959731],[0.982200]]

println("ok")

savefig(fig,"saved_plots/22.06.15_Solvers.pdf")
savefig(fig,"saved_plots/22.06.15_Solvers.png")


# 4.31
# 3.96
# Error









# writec123tofile("plots/testing1.csv",[1.0001,2.,3.],5)
# 


# DONE: Add coupling terms 2f(i)-f(i+1)-f(i-i)
# Understand the discretizing integral and meeting mat. from 16.03


# Use the StochasticDiffEq package to achive the correct result for different solvers
# SDEFunction()
# SDEProblem()
# Use the SimpleDiffEq package to get the SimpleEM for fixed stepsize Euler-Maruyama




# The equation to solve using different schemes:
# dS/dϕ     , S = 1/2 m δτ ∑[(ϕ_i+1 - ϕ_i)^2 / δτ^2 + ω^2ϕ_i^2]
# This means feeding S to a solver
# But here ϕ is an array, so can make a system of equations:
# dS/dϕ_i   , S = 1/2 m δτ [((\phi_i+1 - \phi_i)^2 +(ϕ_i - ϕ_i-1)^2) / δτ^2 + ω^2ϕ_i^2]
#               = 1/2 m δτ [((\phi_i+1 - \phi_i)^2 +(ϕ_i - ϕ_i-1)^2) / δτ^2 + ω^2ϕ_i^2]



# function Langevin(N,a,m,mu,la,gaussianD)
#     n_tau = 16
#     F = [20. for i = 1:n_tau]
#     F2 = [20. for i = 1:n_tau]
#     F3 = [20. for i = 1:n_tau]
#     Flist = Matrix{Float64}(undef,N+1,n_tau)
#     F2list = Matrix{Float64}(undef,N+1,n_tau)
#     F3list = Matrix{Float64}(undef,N+1,n_tau)
#     Flist[1,:] = F
#     F2list[1,:] = F2
#     F3list[1,:] = F3
#     dt = 0.001
#     timespan = (0.0,dt)
#     randoms1 = rand(gaussianD,N*n_tau)
#     for i=1:N
#         # println(F)
#         for ii = 1:n_tau
#             ϕ₋₁ = F[(ii-2+n_tau)%n_tau+1]; ϕ₊₁ = F[(ii)%n_tau+1]; ϕ0 = F[ii]
#             f(ϕ,t,p) = (m/a*(2ϕ-(ϕ₊₁+ϕ₋₁)) + m*mu*a*ϕ)*dt
#             prob = ODEProblem(f,ϕ0,timespan)
#             sol = solve(prob,Euler(),dt=dt,abstol=1e-8,reltol=1e-8)
#             sol3 = solve(prob,ImplicitEuler(),dt=dt,abstol=1e-8,reltol=1e-8)
#             # println(sol(0.01))
#             F[ii] -= sol(dt)*dt - sqrt(2*dt/a)*randoms1[n_tau*(i-1)+ii]
#             F2[ii] -= ActionDer(a,m,mu,la,F2[ii],F2[(ii-2+n_tau)%n_tau+1],F2[(ii)%n_tau+1])*dt - sqrt(2*dt/a)*randoms1[n_tau*(i-1)+ii]
#             F3[ii] -= sol3(dt)*dt - sqrt(2*dt/a)*randoms1[n_tau*(i-1)+ii]
#         end
#         Flist[i+1,:] = F
#         F2list[i+1,:] = F2
#         F3list[i+1,:] = F3
#     end
#     return Flist, F2list, F3list
# end
# res1, res2, res3 = Langevin(10,0.5,1,1,0,gaussianD);

# begin
#     plot(res1[:,1])
#     plot!(res2[:,1])
#     plot!(res3[:,1])
# end




"""
`∂ϕ/∂ϕⱼ = ∂/∂ϕⱼ m/2 a [(ϕⱼ²-2(ϕⱼ)(ϕⱼ₊₁+ϕⱼ₋₁))/a² + μϕⱼ²]`  
`       = m a [(ϕⱼ - ϕⱼ₊₁ - ϕⱼ₋₁)/a² + μϕⱼ]`
[∂ϕ/∂ϕ₁,∂ϕ/∂ϕ₂]
"""
function ActionLDerSchem(du, u, params, t)
    p = params.p
    xR = @view u[:]
    F_diff_m1 = xR .- xR[vcat(end,1:end-1)]   # dx_j - dx_{j-1}
    F_diff_p1 = xR[vcat(2:end,1)] .- xR       # dx_{j+1} - dx_j

    du .= p.m .* (F_diff_p1 .- F_diff_m1) ./ p.a^2 .- (p.mu .* xR)
end
# ActionLDerSchem([1,2,1,1,2,1],params)

function RandScale(du, u, param, t)
    a = param.p.a
    du .= sqrt.(2. ./ a)
end

function LangevinSchem(N,a,m,mu,la,gaussianD)
    n_tau = 16
    F0 = [20. for i = 1:n_tau]
    Flist = Matrix{Float64}(undef,N+1,n_tau)
    Flist[1,:] = F0
    dt = 0.01
    timespan = (0.0,3*N)
    # params = Lvector(p=struct w fields m μ λ)
    params = LVector(p=AHO_Param(a,m,mu,la))
    # Function to calculate change in action for whole path
    sdeprob1 = SDEProblem(ActionLDerSchem,RandScale,F0,timespan,params)

    @time sol = solve(sdeprob1, Euler(), progress=true, saveat=0.1/dt, savestart=false,
                dtmax=1e-3, dt=dt, abstol=5e-2,reltol=5e-2)
end

Solution1 = LangevinSchem(80000,0.5,1,1,0,gaussianD)
plot(Solution1)
Solution1.u

begin
    n_burn = 2
    Set1 = Matrix{Float64}(undef,length(Solution1.u[n_burn:end]),length(Solution1.u[1]))
    for i = n_burn:length(Solution1.u)
        Set1[i-n_burn+1,:] = Solution1.u[i]
    end

    # Plot AutoCorrelation
    autocorrdata = AutoCorrR(Set1)
    jkf1 = Jackknife1(autocorrdata)
    # jkf1[:,1]
    display(plot(jkf1[:,1],yerr=jkf1[:,2],title="AutoCorrelation",xlabel="τ",ylabel="Aₒ(τ)"))

    # Plot TPCF
    arr1 = reshape(Set1,:)
    histogram(arr1,bins=[i for i=floor(minimum(arr1)*10)/10:0.1:(floor(maximum(arr1)*10)+1)/10],normed=true,xlabel="x",ylabel="|ψ₀|²",legend=false)
    display(PlotProbDDe(1,1,1,2))

    println("⟨x⟩ = ",Err1(arr1)[1]," with err: ",Err1(arr1)[2])         # - 4.9*10^-4   ± 0.002048
    println("⟨x²⟩ = ",Err1(arr1.^2)[1]," with err: ",Err1(arr1.^2)[2])  # 0.5102        ± 0.002060

    println("⟨x⟩ = ",Jackknife1(arr1)[1]," with err: ",Jackknife1(arr1)[2])         # - 4.9*10^-4   ± 0.002048
    println("⟨x²⟩ = ",Jackknife1(arr1.^2)[1]," with err: ",Jackknife1(arr1.^2)[2])  # 0.5102        ± 0.002060
end






println()
Langevin(20,0.5,1,1,0,gaussianD)

begin
    n_tau=16
    β=8
    a=β/n_tau
    Langv1=Langevin(10000,a,1,1,0,gaussianD,"$(save_date)_L_dt0.001_b8.csv")
end

# Langevin expectationvalues
x1 = Err1(GetData("results/CL_4.csv",4,1))
x2 = Err1(GetData("results/CL_4.csv",4,2))
plot(x1[:,1],yerr=x1[:,2])
plot(x2[:,1],yerr=x2[:,2])

# Metropolis expectationvalues
x2 = Err1(GetData("results/measuredObsHO_1_β8_16.csv",4,2))
plot(x2[:,1],yerr=x2[:,2])









######################################
## Complex Langevin ##################
######################################






ComplexSys = CLangevin(20000,0.5,1,1,0.4,gaussianD,"CL_2")
incsize1= 0.1
for i = 0:0.1:π
    ComplexSys = CLangevin(20000,0.5,1,exp(i*im),0,gaussianD,"CL_2")
    display(scatter(ComplexSys[1],ComplexSys[2]))
    arr1 = float.(ComplexSys[1])
    println("i: ",i," e^z: ",exp(i*im))
    println("⟨xᵣ²⟩: ",mean(ComplexSys[1].^2)," ⟨xᵢₘ²⟩: ",mean(ComplexSys[2].^2))
    display(histogram(arr1,bins=[i for i=floor(minimum(arr1)*10)/10:incsize1:(floor(maximum(arr1)*10)+1)/10],normed=true,xlabel="x",ylabel="|ψ_0|²"))
end


# μ = e^iϕ, ϕ = (0,2π) (+n*2π)
ComplexSys = CLangevin(20000,0.5,1,0.05*im+1,0,gaussianD,"CL_2")
# ComplexSys = CLangevin(20000,0.5,1,1,0,gaussianD,"CL_2")
for i = 0:11
    if i==0
        # Calculate the analytical result 1/μ = ⟨z²⟩, where μ = exp(nπi/6), n = (0,11)
        # ⟹ 1/μ = exp(-nπi/6), n = (0,11)
        scatter([cos(ii*π/6) for ii=0:11],[sin(ii*π/6) for ii=0:11],color="red",marker=:x,legend=false)#:inside)
        # scatter([real(exp(-im*ii*π/6)) for ii=0:11],[imag(exp(-im*ii*π/6)) for ii=0:11],color="red",legend=:inside,marker=:x)
    end
    arr2=[]
    for runs = 1:64
        ComplexSys = CLangevin(2000,0.5,1,exp(i*im*π/6),0,gaussianD,"CL_2")
        append!(arr2,getExp2(ComplexSys[1],ComplexSys[2])[1])     # ⟨x²⟩
    end
    # display(scatter(ComplexSys[1],ComplexSys[2]))
    # arr1 = float.(ComplexSys[1])
    println("i: ",i,"e^z:",exp(i*im))
    # display(histogram(arr1,bins=[i for i=floor(minimum(arr1)*10)/10:incsize1:(floor(maximum(arr1)*10)+1)/10],normed=true,xlabel="x",ylabel="|ψ_0|²"))
    if in(i,[0,1,2,3,9,10,11])
        arr3 = [mean(arr2),Err1(real.(arr2))[2],Err1(imag.(arr2))[2]]
        fig1 = scatter!([real(arr3[1])],[imag(arr3[1])],xerr=arr3[2],yerr=arr3[3],color="blue",marker=:cross)
        # fig1 = scatter!([real(arr2[1])],[imag(arr2[1])],xerr=arr2[2],yerr=arr2[3],color="blue",marker=:cross)
        display(fig1)
        if true
            if i == 11
                savefig(fig1,"plots/22.04.22_CL_gauss_mod2.pdf") # This is how to save a Julia plot as pdf !!!
            end
        end
    end
end
# Diverges to NaN coordinates late in τ time when Re(z) → 0, Im(z) → 1
# Scatterplot showes values collected moves from only real part to uniform real/complex parts
# Find out for which values eᶻ should diverge

# At i=0.8 to i=0.9 ⟨x²⟩ gets 10% error. At i=1.5 (π/2), ⟨x²⟩=7.3


# scatter(ComplexSys[3],ComplexSys[4],yrange=[-0.004,0.003],xlabel="Re[ρ]",ylabel="Im[ρ]")
ComplexSys[1]
scatter(ComplexSys[1],ComplexSys[2])

# NIntegrate[ x^2*Exp[-(1/2)*m*\[Mu]*x^2 - m*(\[Lambda]/24)*x^4], {x, -\[Infinity], \[Infinity]}]
function getExp2(field_r,field_c)
    z = []
    for i = 1:length(field_r)
        append!(z,(field_r[i]+im*field_c[i])^2)
    end
    return append!([mean(z)], Err1(real.(z))[2], Err1(imag.(z))[2])
end


# CL expectationvalues = 1 ???
Err1(ComplexSys[1])                         # ⟨x_r⟩
Err1(ComplexSys[2])                         # ⟨x_i⟩
getExp2(ComplexSys[1],ComplexSys[2])[1]     # ⟨x²⟩
1/(1+0.05*im) #1/μ
arr1 = float.(ComplexSys[1])
incsize1= 0.1
histogram(arr1,bins=[i for i=floor(minimum(arr1)*10)/10:incsize1:(floor(maximum(arr1)*10)+1)/10],normed=true,xlabel="x",ylabel="|ψ_0|²")




# mean(6/(6*(1+1im)+im*(0.4+1im)*ComplexSys))




    # Probability density diagram #
PlotProbDD("results/CL_4.csv",0.1)
PlotProbDDe(1,1,1,3)
    # sampling
scatter(reshape(GetColumn(2,"results/CL_4.csv"),:))#:Int((length(LastRowFromFile(file))-1)/4)+1
    # Autocorrelation
PlotAC("results/CL_1.csv",1000)
# PlotACsb("results/CL_1.csv",1000)
# PlotAC("results/CL_1.csv",false)
# PlotAC("results/CL_1.csv",true)
    # Twopoint Correlation
PlotTPCF("results/CL_3.csv")                # Naive error
PlotTPCF("results/CL_1.csv",true)           # For autocorrelated data
a = [0.990894    0.00115783;
 -0.0086682   0.000855048;
  0.00979547  0.000858429;
 -0.0109495   0.00088357;
 -0.0096282   0.000881336;
 -9.15654e-6  0.000868927;
  0.00361841  0.000861336;
  0.00736314  0.000860249;
  0.0157388   0.00113745;
  0.00736314  0.000860249;
  0.00361841  0.000861336;
 -9.15654e-6  0.000868927;
 -0.0096282   0.000881336;
 -0.0109495   0.00088357;
  0.00979547  0.000858429;
 -0.0086682   0.000855048;]
 plot(a[:,1],yerr=a[:,2])
 PlotEffM("results/CL_1.csv")



















######################################
## Complex Langevin solver package ###
######################################



mu = exp(im*π/3)
Solution1 = CLangevinSchem(80000,0.5,1,mu,0)
plot(Solution1)
Solution1.u

begin
    n_tau = 16
    n_burn = 2
    Set1 = Matrix{Float64}(undef,length(Solution1.u[n_burn:end]),length(Solution1.u[1]))
    for i = n_burn:length(Solution1.u)
        Set1[i-n_burn+1,:] = Solution1.u[i]
    end
    Set1r = Set1[:,1:n_tau]
    # Plot AutoCorrelation
    autocorrdata = AutoCorrR(Set1r)
    jkf1 = Jackknife1(autocorrdata)
    # jkf1[:,1]
    display(plot(jkf1[:,1],yerr=jkf1[:,2],xlabel="τ",ylabel="Aₒ(τ)",legend=false))#,title="AutoCorrelation"
    savefig("plots/$(save_date)_CL_mu$(round(mu,digits=3))_NewS_AC.pdf")
    savefig("plots/$(save_date)_CL_mu$(round(mu,digits=3))_NewS_AC.png")

    # Plot TPCF
    arr1 = reshape(Set1r,:)
    histogram(arr1,bins=[i for i=floor(minimum(arr1)*10)/10:0.1:(floor(maximum(arr1)*10)+1)/10],normed=true,xlabel="x",ylabel="|ψ₀|²",legend=false)
    display(PlotProbDDe(1,1,1,2))
    savefig("plots/$(save_date)_CL_mu$(round(mu,digits=3))_NewS_PDD.pdf")
    savefig("plots/$(save_date)_CL_mu$(round(mu,digits=3))_NewS_PDD.png")

    println("⟨x⟩ = ",Err1(arr1)[1]," with err: ",Err1(arr1)[2])         # - 4.9*10^-4   ± 0.002048
    println("⟨x²⟩ = ",Err1(arr1.^2)[1]," with err: ",Err1(arr1.^2)[2])  # 0.5102        ± 0.002060

    println("⟨x⟩ = ",Jackknife1(arr1)[1]," with err: ",Jackknife1(arr1)[2])         # - 4.9*10^-4   ± 0.002048
    println("⟨x²⟩ = ",Jackknife1(arr1.^2)[1]," with err: ",Jackknife1(arr1.^2)[2])  # 0.5102        ± 0.002060
end






# function ActionDerSchem(du, u, params, t)
#     p = params.p
#     xR = @view u[1:div(end,2)]
#     xI = @view u[div(end,2)+1:end]
#     Fr_diff_m1 = xR .- xR[vcat(end,1:end-1)]   # dx_j - dx_{j-1}
#     Fr_diff_p1 = xR[vcat(2:end,1)] .- xR       # dx_{j+1} - dx_j
#     Fi_diff_m1 = xI .- xI[vcat(end,1:end-1)]   # dx_j - dx_{j-1}
#     Fi_diff_p1 = xI[vcat(2:end,1)] .- xI       # dx_{j+1} - dx_j
#     du[1:div(end,2)] .= p.m .* real.(Fr_diff_p1 .- Fr_diff_m1 .+ im .* (Fi_diff_p1 .- Fi_diff_m1)) ./ p.a^2 .- real.(p.mu .* xR .+ im .* (p.mu .* xI))
#     du[div(end,2)+1:end] .= p.m .* imag.(im .* (Fi_diff_p1 .- Fi_diff_m1) .+ (Fr_diff_p1 .- Fr_diff_m1)) ./ p.a^2 .- imag.(p.mu .* xR .+ im .* (p.mu .* xI))
# end






fig1 = 0
fig2 = 0
savefig_name = "$(savefig_folder)$(save_date)_CL"
for i = 0:11
    println("Beginning i = ",i)
    n_burn = 20
    n_runs = 4
    arr2 = Matrix{Complex}(undef,n_runs,3)
    mu = exp(i*im*π/6)
    # ComplexSys = Matrix{Float64}(undef,0,0)
    for runs = 1:n_runs
        # ComplexSys = CLangevin(2000,0.5,1,exp(i*im*π/6),0,gaussianD,"CL_2")
        Solution1 = LangevinGaussSchem(8000,0.5,1,mu,0,gaussianD)
        # ComplexSys = Solution1.u[n_burn:end,:]
        ComplexSys = Matrix{Float64}(undef,length(Solution1.u[n_burn:end]),length(Solution1.u[1]))
        for i = n_burn:length(Solution1.u)
            ComplexSys[i-n_burn+1,:] = Solution1.u[i]
        end
        if i==0 && runs==1
            show(IOContext(stdout, :limit => true),"text/plain",ComplexSys);println("\nMatrix of ",length(ComplexSys[:,1])," rows")
        end
        println("Simulated ",i,"/11.",runs,"/",n_runs)
        println("ComplexSys lengths: ",length(ComplexSys[1,:]),", ",length(ComplexSys[1,1:div(end,2)]),", ",length(ComplexSys[1,div(end,2)+1:end]))
        z = (ComplexSys[:,1:div(end,2)] .+ (im .* ComplexSys[:,div(end,2)+1:end])).^2
        arr2[runs,:]=[mean(z), Err1(real.(z))[2], Err1(imag.(z))[2]]     # ⟨x²⟩
        println("i = ",i,", ⟨x²⟩ = ",round(arr2[runs,1],digits=3))
        if i==0
            autocorrdata = AutoCorrR(ComplexSys[:,1:div(end,2)])
            jkf1 = Jackknife1(autocorrdata)
            plt1 = plot(jkf1[:,1],yerr=jkf1[:,2],xlabel="τ",ylabel="Aₒ(τ)",legend=false)#,title="AutoCorrelation"
            savefig(plt1,"$(savefig_name)_mu$(round(mu,digits=3))_NewS_GaussModl_AC.pdf")
            savefig(plt1,"$(savefig_name)_mu$(round(mu,digits=3))_NewS_GaussModl_AC.png")
        end
    end
    # display(scatter(ComplexSys[1],ComplexSys[2]))
    # arr1 = float.(ComplexSys[1])
    if i==0
        # Calculate the analytical result 1/μ = ⟨z²⟩, where μ = exp(nπi/6), n = (0,11)
        # ⟹ 1/μ = exp(-nπi/6), n = (0,11)
        fig1 = scatter([cos(ii*π/6) for ii=0:11],[sin(ii*π/6) for ii=0:11],color="red",marker=:x,legend=false)#:inside)
        fig2 = scatter([cos(ii*π/6) for ii=0:11],[sin(ii*π/6) for ii=0:11],color="red",marker=:x,legend=false)#:inside) 
        # scatter([real(exp(-im*ii*π/6)) for ii=0:11],[imag(exp(-im*ii*π/6)) for ii=0:11],color="red",legend=:inside,marker=:x)
    end
    println("i: ",i," μ = e^z: ",round(exp(i*im),digits=3))
    # display(histogram(arr1,bins=[i for i=floor(minimum(arr1)*10)/10:incsize1:(floor(maximum(arr1)*10)+1)/10],normed=true,xlabel="x",ylabel="|ψ_0|²"))
    if in(i,[0,1,2,3,9,10,11])
        arr3 = [mean(arr2[:,1]),Err1(real.(arr2[:,1]))[2],Err1(imag.(arr2[:,1]))[2]]
        fig1 = scatter!(fig1,[real(arr3[1])],[imag(arr3[1])],xerr=arr3[2],yerr=arr3[3],color="blue",marker=:cross)
        # fig1 = scatter!([real(arr2[1])],[imag(arr2[1])],xerr=arr2[2],yerr=arr2[3],color="blue",marker=:cross)
        display(fig1)
        if true
            if i == 11
                savefig(fig1,"$(savefig_name)_NewS_Cmodel1.pdf") # This is how to save a Julia plot as pdf !!!
                savefig(fig1,"$(savefig_name)_NewS_Cmodel1.png") # This is how to save a Julia plot as pdf !!!
            end
        end

        if in(i,[0,1,2,10,11])
            fig2 = scatter!(fig2,[real(arr3[1])],[imag(arr3[1])],xerr=arr3[2],yerr=arr3[3],color="blue",marker=:cross)
            if true
                if i == 11
                    savefig(fig2,"$(savefig_name)_NewS_Cmodel2.pdf") # This is how to save a Julia plot as pdf !!!
                    savefig(fig2,"$(savefig_name)_NewS_Cmodel2.png") # This is how to save a Julia plot as pdf !!!
                end
            end
        end
    end
end
