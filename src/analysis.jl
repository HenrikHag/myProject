using FFTW, Plots, Statistics, StatsBase, Gnuplot

export Err1, Jackknife1
export LastRowFromFile, GetColumn, GetData, GetTwoPointData, GetTP1data, GetExpXData, GetLastMean
export AutoCorrR, ACIntegrated, TPCF, TPCFe, EffM, Exp_x2e, Exp_x2, Autocorrelation_BySummation
export PlotAC, PlotACsb, PlotTPCF, PlotTPCFe, PlotTPCFe!, PlotEffM
export PlotProbDD, PlotProbDDe, PlotProbDDe!#, PlotACwt, PlotACsbwt, PlotTPCFwt
export Autocorrelation_BySummation, PlotAC_BySummation
# using PlotExp, plot_x



#                                               #
#           Mean and Error Estimation           #
#                                               #
"""
Calculate mean and error of elements in an array  
Pass a matrix to calculate mean and error for each column  
"""
function Err1(array1::AbstractArray)
    # mean1 = mean(array1)
    # err1 = sum((array1.-mean1).^2)
    #     # for i=1:length(array1)
    #     #     err1 += (array1[i]-mean1)^2
    #     # end
    # err1 /= length(array1)*(length(array1)-1)
    # return [mean(array1), √(err1)]#std(array1)/√length(array1)] #  √(var(array1)/length(array1)),
    return [mean(array1), std(array1)/√length(array1)]
end
function Err1(matrix1::AbstractMatrix)
    err1 = Matrix{Float64}(undef,length(matrix1[1,:]),2)
    for i=1:length(matrix1[1,:])
        err1[i,:] = Err1(matrix1[:,i])
    end
    return err1
end



"""
Does Jackknife analysis with `Jackknife binsize = n-1`, where `n = length(array1)`  
If type is matrix it returnes a matrix of results of Jacknife analysis for each column  
If binsize is specified, does Jackknife analysis with `Jackknife binsize = n-binsize`  
If defIntACtimeBin is specified, uses Integrated AC time as `binsize`
"""
function Jackknife1(array1::AbstractVector)
    leng1 = length(array1)
    sum1 = sum(array1)
    jf = Vector{Float64}(undef,leng1)
    fill!(jf,sum1)
    for k = 1:leng1
        jf[k] -= array1[k]
    end
    jf = jf./(leng1-1)
    jf = jf.-sum1/leng1
    jf = jf.^2
    jfvm = mean(jf)
    jfvm *= (length(array1)-1)
    return [mean(array1),√(jfvm)]
end
function Jackknife1(array1::AbstractVector,binsize::Integer)
    N_B = floor(Int64,length(array1)/binsize) # ommiting last not-full bin
    leng2 = N_B*binsize
    array2 = array1[1:leng2]
    sum1 = sum(array2)
    jf = Vector{Float64}(undef,N_B)
    fill!(jf,sum1)
    for k = 1:N_B
        jf[k] -= sum(array2[(k-1)*binsize+1:k*binsize])
    end
    jf = ((jf ./ (leng2 - binsize)) .- (sum1/leng2)).^2
    jfvm = mean(jf)
    jfvm *= (N_B - 1)
    return [mean(array1),sqrt(jfvm)]
end
function Jackknife1(array1::AbstractVector,defIntACtimeBin::Bool)
    if defIntACtimeBin
        return Jackknife1(array1,ceil(Int64,ACIntegrated(array1)))
    end
    return Jackknife1(array1)
end
function Jackknife1(matrix1::AbstractMatrix)
    jf = Matrix{Float64}(undef,length(matrix1[1,:]),2)
    for i=1:length(matrix1[1,:])
        jf[i,:] = Jackknife1(matrix1[:,i])
    end
    return jf
end
function Jackknife1(matrix1::AbstractMatrix,binsize::Integer)
    jf = Matrix{Float64}(undef,length(matrix1[1,:]),2)
    for i=1:length(matrix1[1,:])
        jf[i,:] = Jackknife1(matrix1[:,i],binsize)
    end
    return jf
end
function Jackknife1(matrix1::AbstractMatrix,defIntACtimeBin::Bool)
    jf = Matrix{Float64}(undef,length(matrix1[1,:]),2)
    if defIntACtimeBin
        for i=1:length(matrix1[1,:])
            jf[i,:] = Jackknife1(matrix1[:,i],defIntACtimeBin)
        end
    else
        for i=1:length(matrix1[1,:])
            jf[i,:] = Jackknife1(matrix1[:,i])
        end
    end
    return jf
end



#                                               #
#               File handling (reading)         #
#                                               #
"""
Return elements separated by "," in last row of file as Vector{Float64}  
O(1) last row file lookup
"""
function LastRowFromFile(filename)
    # row = split(last(readlines(filename)),",")
    row = []
    open(filename) do f
        # a = first(Iterators.reverse(eachline(f)))
        # println(iterate(a))
        seekend(f)
        seek(f,position(f)-2)
        while Char(peek(f)) != '\n'
            seek(f,position(f)-1)
        end
        Base.read(f, Char)
        append!(row, split(Base.read(f, String),","))
    end
    rowData = Vector{Float64}(undef,length(row))
    for i = 1:length(row)
        rowData[i] = parse.(Float64,row[i])
    end
    return rowData
end
# lastRow = LastRowFromFile("results/expfull.csv")


"""
Returns column(s) of file delimited by ","
"""
function GetColumn(col::Integer,filename::String)
    al = Vector{Float64}(undef,0)
    for c = col
        for r = readlines(filename)
            push!(al,parse.(Float64,split(r,",")[c]))
        end
    end
    return al
end
function GetColumn(col,filename::String)
    all1 = Matrix{Float64}(undef,countlines(filename),length(col))
    r1 = 1
    for r = readlines(filename)
        all1[r1,:] = parse.(Float64,split(r,",")[col])
        r1 += 1
    end
    return all1
end


"""
Get columns from "filename" throwing away the index at column 1,  
then taking a group of columns 1:n_tau corresponding to a dataset
"""
function GetData(filename,Nn_tau,n)
    ind = div(length(LastRowFromFile(filename))-1,Nn_tau)
    return GetColumn(((n-1)*ind+2:n*ind+1),filename)
end


"""
Gets the last n_tau columns from "filename" (measuredObs-file)
"""
function GetTwoPointData(filename)
    return GetData(filename,4,4)
    #GetColumn((3*ind+2:4*ind+1),filename)#,ind,(3*ind:4*ind+1)
end

"""
Gets the second to last n_tau columns from "filename" (measuredObs-file)
"""
function GetTP1data(filename)
    return GetData(filename,4,3)
end


"""
Gets the n-th n_tau columns from "filename" (expfull/measuredObs-file)  
n = 1: ⟨x̂⟩  
n = 2: ⟨x̂²⟩  
n = 3: ⟨x₁xᵢ⟩  
Specify number (array or Int) for a specific column in the n-th n_tau column  
"""
function GetExpXData(filename)
    return GetData(filename,3,1)
end
function GetExpXData(filename, n)
    return GetData(filename,3,n)
end
function GetExpXData(filename, n, number)
    ind = div(length(LastRowFromFile(filename))-1,3)
    # if ∉(max(number),[1:ind])
    #     return ErrorException("Number not in range of 1:n_tau")
    # end
    return GetColumn(number.+((n-1)*ind+1),filename)
end


"""
Get last row of file with means  
Returns Float64 of elements in range 2:n_tau+1
"""
function GetLastMean(meanf, n_tau)
    return parse.(Float64,split(last(readlines(meanf)),","))[2:n_tau+1]
end








#                                       #
#           Auto Correlation            #
#                                       #
"""
returns autocorrelation of a vector or matrix by slow summation
"""
function Autocorrelation_BySummation(arrayC::AbstractVector)
    a = copy(arrayC)
    a = a .- mean(a)
    append!(a,zeros(length(arrayC)))
    acc = [sum(a.*circshift(a,-i)) for i=0:length(arrayC)-1]
    var = acc[1]
    return acc./var
end
function Autocorrelation_BySummation(arrayC::AbstractVector,Nfirst::Integer)
    a = copy(arrayC)
    a = a .- mean(a)
    append!(a,zeros(length(arrayC)))
    acc = [sum(a.*circshift(a,-i)) for i=0:Nfirst-1]
    var = acc[1]
    return acc./var
end
function Autocorrelation_BySummation(arrayC::AbstractVector,norm::Bool)
    a = copy(arrayC)
    a = a .- mean(a)
    println(mean(a))
    append!(a,zeros(length(arrayC)))
    acc = [sum(a.*circshift(a,-i)) for i=0:length(arrayC)-1]
    if norm
        var = acc[1]
        return acc./var
    end
    return acc
end
function Autocorrelation_BySummation(matrixC::AbstractMatrix)
    CorrD = Matrix{Float64}(undef,length(matrixC[1,:]),length(matrixC[:,1]))
    for i=1:length(matrixC[1,:])
        CorrD[i,:] = Autocorrelation_BySummation(matrixC[:,i])
    end
    return CorrD
end
function Autocorrelation_BySummation(matrixC::AbstractMatrix,Nfirst::Integer)
    CorrD = Matrix{Float64}(undef,length(matrixC[1,:]),length(matrixC[:,1]))
    for i=1:length(matrixC[1,:])
        CorrD[i,:] = Autocorrelation_BySummation(matrixC[:,i],Nfirst)
    end
    return CorrD
end
function Autocorrelation_BySummation(matrixC::AbstractMatrix,norm::Bool)
    CorrD = Matrix{Float64}(undef,length(matrixC[1,:]),length(matrixC[:,1]))
    for i=1:length(matrixC[1,:])
        CorrD[i,:] = Autocorrelation_BySummation(matrixC[:,i],norm)
    end
    return CorrD
end

"""
Plots the linear autocorrelation from a matrix by Jacknife average of columns
"""
function PlotAC_BySummation(matrix1::AbstractMatrix)
    autocorrdata = Autocorrelation_BySummation(matrix1)
    jkf1 = Jackknife1(autocorrdata)
    plot(jkf1[:,1],yerr=jkf1[:,2],xlabel="Δt",ylabel="Aₒ(Δt)")
end
function PlotAC_BySummation(matrix1::AbstractMatrix,Nfirst::Integer)
    autocorrdata = Autocorrelation_BySummation(matrix1,Nfirst)
    jkf1 = Jackknife1(autocorrdata)
    plot(jkf1[:,1],yerr=jkf1[:,2],xlabel="Δt",ylabel="Aₒ(Δt)")
end
function PlotAC_BySummation(matrix1::AbstractMatrix,norm::Bool)
    autocorrdata = Autocorrelation_BySummation(matrix1,norm)
    jkf1 = Jackknife1(autocorrdata)
    plot(jkf1[:,1],yerr=jkf1[:,2],xlabel="Δt",ylabel="Aₒ(Δt)")
end
function PlotAC_BySummation(vector1::AbstractVector)
    autocorrdata = Autocorrelation_BySummation(vector1)
    plot(autocorrdata,xlabel="Δt",ylabel="Aₒ(Δt)")
end
function PlotAC_BySummation(vector1::AbstractVector,Nfirst::Integer)
    autocorrdata = Autocorrelation_BySummation(vector1,Nfirst)
    plot(autocorrdata,xlabel="Δt",ylabel="Aₒ(Δt)")
end
function PlotAC_BySummation(vector1::AbstractVector,norm::Bool)
    autocorrdata = Autocorrelation_BySummation(vector1,norm)
    plot(autocorrdata,xlabel="Δt",ylabel="Aₒ(Δt)")
end

"""
returns real part of FFT AutoCorrelation of arrayC.  
returns a matrix of correlations → if matrix of configs ↓ is passed.  
`[t_MC,xᵢ] → [xᵢ,AC(t_MC)]`
"""
function AutoCorrR(arrayC::AbstractArray)
    arrayCm = copy(arrayC) .- mean(arrayC)
    arrayCm = append!(arrayCm,[0 for i = 0:length(arrayC)]) # Padding
    autoCorr = fft(arrayCm)
    arrayCm = (abs.(autoCorr)).^2
    autoCorr = real.(ifft(arrayCm))[1:length(arrayC)]
    e1 = autoCorr[1]
    return autoCorr./e1
end
function AutoCorrR(arrayC::AbstractArray,norm::Bool)
    arrayCm = copy(arrayC) .- mean(arrayC)
    arrayCm = append!(arrayCm,[0 for i = 0:length(arrayC)]) # Padding
    autoCorr = fft(arrayCm)
    arrayCm = (abs.(autoCorr)).^2
    autoCorr = real.(ifft(arrayCm))[1:length(arrayC)]
    e1 = autoCorr[1]
    if !norm
        return autoCorr
    end
    return autoCorr./e1
end
function AutoCorrR(arrayC::AbstractArray,norm::Bool,padded::Bool)
    arrayCm = copy(arrayC) .- mean(arrayC)
    if padded
        arrayCm = append!(arrayCm,[0 for i=0:length(arrayC)]) # Padding
    end
    autoCorr = fft(arrayCm)
    arrayCm = (abs.(autoCorr)).^2
    autoCorr = real.(ifft(arrayCm))[1:length(arrayC)]
    if !norm
        return autoCorr
    end
    e1 = autoCorr[1]
    return autoCorr./e1
end
function AutoCorrR(matrixC::AbstractMatrix)
    CorrD = Matrix{Float64}(undef,length(matrixC[1,:]),length(matrixC[:,1]))
    for i = 1:length(matrixC[1,:])
        CorrD[i,:] = AutoCorrR(matrixC[:,i])
    end
    return CorrD
end
function AutoCorrR(matrixC::AbstractMatrix,norm::Bool)
    CorrD = Matrix{Float64}(undef,length(matrixC[1,:]),length(matrixC[:,1]))
    for i = 1:length(matrixC[1,:])
        CorrD[i,:] = AutoCorrR(matrixC[:,i],norm)
    end
    return CorrD
end
function AutoCorrR(matrixC::AbstractMatrix,norm::Bool,padded::Bool)
    CorrD = Matrix{Float64}(undef,length(matrixC[1,:]),length(matrixC[:,1]))
    for i = 1:length(matrixC[1,:])
        CorrD[i,:] = AutoCorrR(matrixC[:,i],norm,padded)
    end
    return CorrD
end

"""
Computes the integrated autocorrelation time from array  
If input is matrix, returns IAC time of `⟨AC(t_MC)⟩ₓ`
"""
function ACIntegrated(array1::AbstractVector)
    autocorrdata = AutoCorrR(array1)
    index1 = length(autocorrdata)
    for i = 1:length(autocorrdata)
        if autocorrdata[i] < 0
            index1 = i
            # println("First negative value of autocorr at index: ",i)
            break
        end
    end
    acInt = sum(autocorrdata[2:index1]) + 0.5
    # acInt *= (length(auto1)-1)/length(auto1)
    return acInt
end
function ACIntegrated(matrix1::AbstractMatrix)
    autocorrdata = AutoCorrR(matrix1)
    auto1 = Err1(autocorrdata)[:,1] # Average over x of ACₓ(t_MC)
    index1 = length(auto1)
    for i = 1:length(auto1)
        if auto1[i] < 0
            index1 = i
            # println("First negative value of autocorr at index: ",i)
            break
        end
    end
    acInt = sum(auto1[2:index1]) + 0.5
    # acInt *= (length(auto1)-1)/length(auto1)
    return acInt
end


#                                       #
#         Two-Point Correlation         #
#                                       #
"""
Returns the TPCF  
If argument is Vector, from vector  
If argument is Matrix, from rows of Matrix, giving estimate of error of different columns  
If argument is String, from rows of data in file  
Optional: Bool for Jackknife
"""
function TPCF(filename::String)
    tpcr = Err1(GetTwoPointData(filename))
    return tpcr
end
function TPCF(filename::String,Jackknife::Bool)
    if Jackknife
        tpcr = Jackknife1(GetTwoPointData(filename),true)
    else
        tpcr = Err1(GetTwoPointData(filename))
    end
    return tpcr
end
function TPCF(array1::AbstractVector)
    twopointcorr1 = Vector{Float64}(undef,length(array1))
    for i = 0:length(array1)-1
        twopointcorr1[i+1] = sum(array1 .* circshift(array1,-i))
    end
    return twopointcorr1./length(array1)
end
function TPCF(matrix1::AbstractMatrix)
    tpcr = Matrix{Float64}(undef,length(matrix1[1,:]),length(matrix1[:,1]))
    for i = 1:length(matrix1[1,:])
        tpcr[i,:] = TPCF(matrix1[:,i])
    end
    return Err1(tpcr)
end
function TPCF(matrix1::AbstractMatrix,Jackknife::Bool)
    if Jackknife
        tpcr = Matrix{Float64}(undef,length(matrix1[1,:]),length(matrix1[:,1]))
        for i = 1:length(matrix1[1,:])
            tpcr[i,:] = TPCF(matrix1[:,i])
        end
        return Jackknife1(tpcr,true)
    end
    return TPCF(matrix1)
end

"""
returns the analytical TPCF for the system
"""
function TPCFe(a,m,ω,n_tau)
    R = 1 + (a*ω)^2/2 - a*ω*sqrt(1+(a*ω)^2/4)
    return [(R^i+R^(n_tau-i)) for i=0:n_tau-1]./(1-R^n_tau)./(2*m*ω)
end



#                                       #
#            Effective mass             #
#                                       #
"""
Calculates the effective mass from data using the two-point correlation function
"""
function EffM(array1::AbstractVector)
    array2 = TPCF(array1)
    effm = Vector{Float64}(undef,length(array1)-2)
    for i=1:length(array1)-2
        effm[i] = 0.5*log10(array1[i]/array1[i+2])
    end
    # display(plot(effm))
    return effm
end
function EffM(matrix1::AbstractMatrix)
    effm = Matrix{Float64}(undef,length(matrix1[:,1])-2,2)
    for i=1:length(matrix1[:,1])-2
        efm = 1/2*log10(matrix1[i,1]/matrix1[i+2,1])
        effm[i,1] = efm
        # Test if out of bounds error occurs by too large errors
        effm[i,2] = max(
            1/2*log10((abs(matrix1[i,1])+matrix1[i,2])/(abs(matrix1[i+2,1])-matrix1[i+2,2]))-efm,
            efm-1/2*log10((abs(matrix1[i,1])-matrix1[i,2])/(abs(matrix1[i+2,1])+matrix1[i+2,2]))
            )
        # println(1/2*log10((abs(array1[i-1,1])+array1[i-1,2])/(abs(array1[3,2])-array1[3,2]))-1/2*log10(array1[1,1]/array1[3,1]))
        # effm[i-1,2] = (abs(array1[i-1,1])-array1[i-1,2])/(abs(array1[i+1,2])+array1[i+1,2])-effm[i-1,1]#1/2*log10()
    end
    # display(plot(effm[:,1],yerr=effm[:,2]))
    return effm
end
# function EffM(matrix1::AbstractMatrix)
#     effm = Matrix{Float64}(undef,length(matrix1[:,1])-2,2)
#     efm = Array{Float64}(undef,length(matrix1[1,:]))
#     for i=1:length(matrix1[:,1])-2
#         for ii = 1:length(matrix1[1,:])
#             efm[ii] = 0.5*log10(matrix1[i,ii]/matrix1[i+2,ii])
#         end
#         effm[i,2] = Err1(efm)[2]
#         # Test if out of bounds error occurs by too large errors
#         # effm[i,2] = max(
#             # 1/2*log10((abs(matrix1[i,1])+matrix1[i,2])/(abs(matrix1[i+2,1])-matrix1[i+2,2]))-efm,
#             # efm-1/2*log10((abs(matrix1[i,1])-matrix1[i,2])/(abs(matrix1[i+2,1])+matrix1[i+2,2]))
#             # )
#         # println(1/2*log10((abs(array1[i-1,1])+array1[i-1,2])/(abs(array1[3,2])-array1[3,2]))-1/2*log10(array1[1,1]/array1[3,1]))
#         # effm[i-1,2] = (abs(array1[i-1,1])-array1[i-1,2])/(abs(array1[i+1,2])+array1[i+1,2])-effm[i-1,1]#1/2*log10()
#     end
#     effm[:,1] .= Err1(transpose(matrix1))[length(effm[:,1]),1]
#     # display(plot(effm[:,1],yerr=effm[:,2]))
#     return effm
# end
# function EffM(matrix1::AbstractMatrix,Jackknife::Bool)
#     effm = Matrix{Float64}(undef,length(matrix1[:,1])-2,2)
#     efm = Array{Float64}(undef,length(matrix[1,:]))
#     for i=1:length(matrix1[:,1])-2
#         for ii = 1:length(matrix1[1,:])
#             efm[i] = 1/2*log10(matrix1[i,ii]/matrix1[i+2,ii])
#         end
#         if Jackknife
#             effm[i,:] = Jackknife1(efm[i])
#         else
#             effm[i,:] = Err1(efm[i])
#         end
#         # Test if out of bounds error occurs by too large errors
#         # effm[i,2] = max(
#             # 1/2*log10((abs(matrix1[i,1])+matrix1[i,2])/(abs(matrix1[i+2,1])-matrix1[i+2,2]))-efm,
#             # efm-1/2*log10((abs(matrix1[i,1])-matrix1[i,2])/(abs(matrix1[i+2,1])+matrix1[i+2,2]))
#             # )
#         # println(1/2*log10((abs(array1[i-1,1])+array1[i-1,2])/(abs(array1[3,2])-array1[3,2]))-1/2*log10(array1[1,1]/array1[3,1]))
#         # effm[i-1,2] = (abs(array1[i-1,1])-array1[i-1,2])/(abs(array1[i+1,2])+array1[i+1,2])-effm[i-1,1]#1/2*log10()
#     end
#     # display(plot(effm[:,1],yerr=effm[:,2]))
#     return effm
# end




#                                               #
#          Expectation values of data           #
#                                               #
"""
Calculates the analytical expectation value ⟨x²⟩ for the Harmonic Oscillator  
with mass m, frequency ω, lattice spacing a, and lattice points n_tau.
"""
function Exp_x2e(n_tau, a, m, ω)
    R = 1 + (a^2*ω^2)/2 - a*ω*sqrt(1+(a^2*ω^2)/4)
    return (1 + R^n_tau)/(1 - R^n_tau)/(2*m*ω)#*sqrt(1+(a*ω)^2/4))
end

"""
Calculates the analytical expectation value ⟨x²⟩ for the Harmonic Oscillator  
taking into consideration the discretization effects.  
with mass m, frequency ω, lattice spacing a, and lattice points n_tau.
"""
function Exp_x2(n_tau, a, m, ω)
    R = 1 + (a^2*ω^2)/2 - a*ω*sqrt(1+(a^2*ω^2)/4)
    return (1+R^n_tau)/(1-R^n_tau)/(2*m*ω*sqrt(1+(a^2*ω^2)/4))
end





#                                       #
#        Plot Auto Correlation          #
#                                       #
"""
Plots AutoCorrelation from file, matrix or vector  
Optional:  
norm; plots the unnormalized autocorrelation  
leng; specify the number to plot in t
"""
function PlotAC(filename::AbstractString)
    data1 = GetData(filename,4,1)
    PlotAC(data1)
end
function PlotAC(filename::AbstractString,norm::Bool)
    data1 = GetData(filename,4,1)
    PlotAC(data1,norm)
end
function PlotAC(filename::AbstractString,leng)
    data1 = GetData(filename,4,1)
    PlotAC(data1,leng)
end
function PlotAC(matrix1::AbstractMatrix)
    jkf1 = Jackknife1(AutoCorrR(matrix1))
    plot(jkf1[:,1],yerr=jkf1[:,2],xlabel="Δt",ylabel="Aₒ(Δt)")
end
function PlotAC(matrix1::AbstractMatrix,norm::Bool)
    autocorrdata = AutoCorrR(matrix1,norm)
    jkf1 = Jackknife1(autocorrdata)
    plot(jkf1[:,1],yerr=jkf1[:,2],xlabel="Δt",ylabel="Aₒ(Δt)")
end
function PlotAC(matrix1::AbstractMatrix,leng)
    if leng > length(matrix1[:,1])
        leng = length(matrix1[:,1])
        println("PlotAC: Length specified to large, using full length ($(length(matrix1[:,1])))")
    end
    jkf1 = Jackknife1(AutoCorrR(matrix1)[:,1:leng])
    plot(jkf1[:,1],yerr=jkf1[:,2],xlabel="Δt",ylabel="Aₒ(Δt)")
end
function PlotAC(vector1::AbstractVector)
    plot(AutoCorrR(vector1),xlabel="Δt",ylabel="Aₒ(Δt)")
end
function PlotAC(vector1::AbstractVector,norm::Bool)
    autocorrdata = AutoCorrR(vector1,norm)
    plot(autocorrdata,xlabel="Δt",ylabel="Aₒ(Δt)")
end
function PlotAC(vector1::AbstractVector,leng)
    if leng > length(vector1)
        leng = length(vector1)
        println("PlotAC: Length specified to large, using full length ($(length(vector1)))")
    end
    plot(AutoCorrR(vector1)[:,1:leng],xlabel="Δt",ylabel="Aₒ(Δt)")
end

# title!("title") to get title on plots
# """
# Plots AutoCorrelation with title from file  
# Optional:  
# fullLength; plots only for first 200 in τ if false  
# leng; specify the number to plot in τ
# """
# function PlotACwt(filename)
#     data1 = GetData(filename,4,1)
#     autocorrdata = AutoCorrR(data1)
#     jkf1 = Jackknife1(autocorrdata)
#     plot(jkf1[:,1],yerr=jkf1[:,2],title="AutoCorrelation",xlabel="τ",ylabel="Aₒ(τ)")
# end
# function PlotACwt(filename,fullLength::Bool)
#     data1 = GetData(filename,4,1)
#     if fullLength
#         autocorrdata = AutoCorrR(data1)
#     else
#         leng = 200
#         autocorrdata = AutoCorrR(data1)[:,1:leng]
#     end
#     jkf1 = Jackknife1(autocorrdata)
#     plot(jkf1[:,1],yerr=jkf1[:,2],title="AutoCorrelation",xlabel="τ",ylabel="Aₒ(τ)")
# end
# function PlotACwt(filename,leng)
#     data1 = GetData(filename,4,1)
#     if leng > length(data1[:,1])
#         leng = length(data1[:,1])
#         println("PlotAC: Length specified to large, using length(data1[:,1]) = N_meas")
#     end
#     autocorrdata = AutoCorrR(data1)[:,1:leng]
#     jkf1 = Jackknife1(autocorrdata)
#     plot(jkf1[:,1],yerr=jkf1[:,2],title="AutoCorrelation",xlabel="τ",ylabel="Aₒ(τ)")
# end

"""
Plots AutoCorrelation with StatsBase package from file  
Optional:  
fullLength; plots only for first few in τ if false  
leng; specify the number to plot in τ
"""
function PlotACsb(filename)
    data1 = GetData(filename,4,1)
    leng = length(data1[:,1])
    autocorrdata = transpose(StatsBase.autocor(data1,[i for i=0:leng-1]))
    jkf1 = Jackknife1(autocorrdata)
    plot(jkf1[:,1],yerr=jkf1[:,2],xlabel="Δt",ylabel="Aₒ(Δt)")
end
function PlotACsb(filename,fullLength::Bool)
    data1 = GetData(filename,4,1)
    if fullLength
        leng = length(data1[:,1])
        autocorrdata = transpose(StatsBase.autocor(data1,[i for i=0:leng-1]))
    else
        autocorrdata = transpose(StatsBase.autocor(data1))
    end
    jkf1 = Jackknife1(autocorrdata)
    plot(jkf1[:,1],yerr=jkf1[:,2],xlabel="Δt",ylabel="Aₒ(Δt)")
end
function PlotACsb(filename,leng)
    data1 = GetData(filename,4,1)
    if leng > length(data1[:,1])
        leng = length(data1[:,1])
        println("PlotAC: Length specified to large, using length(data1[:,1]) = N_meas")
    end
    autocorrdata = transpose(StatsBase.autocor(data1,[i for i=0:leng-1]))
    jkf1 = Jackknife1(autocorrdata)
    plot(jkf1[:,1],yerr=jkf1[:,2],xlabel="Δt",ylabel="Aₒ(Δt)")
end

# title!("title") to get title on plots
# """
# Plots AutoCorrelation with StatsBase package with title from file  
# Optional:  
# fullLength; plots only for first few in τ if false  
# leng; specify the number to plot in τ
# """
# function PlotACsbwt(filename)
#     data1 = GetData(filename,4,1)
#     leng = length(data1[:,1])
#     autocorrdata = transpose(StatsBase.autocor(data1,[i for i=0:leng-1]))
#     jkf1 = Jackknife1(autocorrdata)
#     plot(jkf1[:,1],yerr=jkf1[:,2],title="AutoCorr by StatsBase package",xlabel="τ",ylabel="Aₒ(τ)")
# end
# function PlotACsbwt(filename,fullLength::Bool)
#     data1 = GetData(filename,4,1)
#     if fullLength
#         leng = length(data1[:,1])
#         autocorrdata = transpose(StatsBase.autocor(data1,[i for i=0:leng-1]))
#     else
#         autocorrdata = transpose(StatsBase.autocor(data1))
#     end
#     jkf1 = Jackknife1(autocorrdata)
#     plot(jkf1[:,1],yerr=jkf1[:,2],title="AutoCorr by StatsBase package",xlabel="τ",ylabel="Aₒ(τ)")
# end
# function PlotACsbwt(filename,leng)
#     data1 = GetData(filename,4,1)
#     if leng > length(data1[:,1])
#         leng = length(data1[:,1])
#         println("PlotAC: Length specified to large, using length(data1[:,1]) = N_meas")
#     end
#     autocorrdata = transpose(StatsBase.autocor(data1,[i for i=0:leng-1]))
#     jkf1 = Jackknife1(autocorrdata)
#     plot(jkf1[:,1],yerr=jkf1[:,2],title="AutoCorr by StatsBase package",xlabel="τ",ylabel="Aₒ(τ)")
# end


#                                       #
#       Plot Two-Point Correlation      #
#                                       #

# function PlotTPCF(filename)
#     tpcr = Err1(GetTwoPointData(filename))
#     display(plot(tpcr[:,1],yerr=tpcr[:,2],yrange=[1.4*10^-3,10^2],yaxis=:log, label="⟨x₍ᵢ₊ₓ₎xᵢ⟩",xlabel="Δτ",ylabel="G(Δτ)"))#,title="Two-Point Correlation"
#     # plot!(tpcr[:,1],yerr=tpcr[:,2],yrange=[1.4*10^-3,10^2],yaxis=:log,title="Two-Point Correlation", label="⟨x₍ᵢ₊ₓ₎xᵢ⟩")
#     return tpcr
# end
"""
Plots the Two-Point Correlation Function from file or matrix of data  
If filename and saveToFile (strings) are passed, saves data to file for fitting
"""
function PlotTPCF(matrix1::AbstractMatrix,logplot=true)
    tpcr = TPCF(transpose(matrix1))
    if logplot
        display(plot([0:length(tpcr[:,1])-1],tpcr[:,1],yerr=tpcr[:,2],yrange=[1.4*10^-3,10^2],yaxis=:log,label="⟨x₍ᵢ₊ₓ₎xᵢ⟩",xlabel="Δτ",ylabel="G(Δτ)"))
    else
        display(plot([0:length(tpcr[:,1])-1],tpcr[:,1],yerr=tpcr[:,2], label="⟨x₍ᵢ₊ⱼ₎xᵢ⟩ᵢ",xlabel="Δτ",ylabel="G(Δτ)"))
    end
    # plot!(tpcr[:,1],yerr=tpcr[:,2],yrange=[1.4*10^-3,10^2],yaxis=:log,title="Two-Point Correlation", label="⟨x₍ᵢ₊ₓ₎xᵢ⟩")
    return tpcr
end
function PlotTPCF(matrix1::AbstractMatrix,FirstN::Integer,logplot=true)
    tpcr = TPCF(transpose(matrix1))[1:FirstN,:]
    if logplot
        display(plot([0:length(tpcr[:,1])-1],tpcr[:,1],yerr=tpcr[:,2],yrange=[1.4*10^-3,10^2],yaxis=:log,label="⟨x₍ᵢ₊ₓ₎xᵢ⟩",xlabel="Δτ",ylabel="G(Δτ)"))
    else
        display(plot([0:length(tpcr[:,1])-1],tpcr[:,1],yerr=tpcr[:,2], label="⟨x₍ᵢ₊ⱼ₎xᵢ⟩ᵢ",xlabel="Δτ",ylabel="G(Δτ)"))
    end
    # plot!(tpcr[:,1],yerr=tpcr[:,2],yrange=[1.4*10^-3,10^2],yaxis=:log,title="Two-Point Correlation", label="⟨x₍ᵢ₊ₓ₎xᵢ⟩")
    return tpcr
end
function PlotTPCF(matrix1::AbstractMatrix,Jackknife::Bool,logplot=true)
    tpcr = TPCF(transpose(matrix1),Jackknife)
    if logplot
        display(plot([0:length(tpcr[:,1])-1],tpcr[:,1],yerr=tpcr[:,2],yrange=[1.4*10^-3,10^2],yaxis=:log,label="⟨x₍ᵢ₊ₓ₎xᵢ⟩",xlabel="Δτ",ylabel="G(Δτ)"))
    else
        display(plot([0:length(tpcr[:,1])-1],tpcr[:,1],yerr=tpcr[:,2], label="⟨x₍ᵢ₊ⱼ₎xᵢ⟩ᵢ",xlabel="Δτ",ylabel="G(Δτ)"))
    end
    return tpcr
end
function PlotTPCF(filename::AbstractString,logplot=true)
    tpcr = Err1(GetTwoPointData(filename))
    if logplot
        display(plot([0:length(tpcr[:,1])-1],tpcr[:,1],yerr=tpcr[:,2],yrange=[1.4*10^-3,10^2],yaxis=:log,label="⟨x₍ᵢ₊ₓ₎xᵢ⟩",xlabel="Δτ",ylabel="G(Δτ)"))
    else
        display(plot([0:length(tpcr[:,1])-1],tpcr[:,1],yerr=tpcr[:,2], label="⟨x₍ᵢ₊ⱼ₎xᵢ⟩ᵢ",xlabel="Δτ",ylabel="G(Δτ)"))
    end
    # plot!(tpcr[:,1],yerr=tpcr[:,2],yrange=[1.4*10^-3,10^2],yaxis=:log,title="Two-Point Correlation", label="⟨x₍ᵢ₊ₓ₎xᵢ⟩")
    return tpcr
end
function PlotTPCF(filename::AbstractString,FirstN::Integer,logplot=true)
    tpcr = Err1(GetTwoPointData(filename))[1:FirstN,:]
    if logplot
        display(plot([0:length(tpcr[:,1])-1],tpcr[:,1],yerr=tpcr[:,2],yrange=[1.4*10^-3,10^2],yaxis=:log,label="⟨x₍ᵢ₊ₓ₎xᵢ⟩",xlabel="Δτ",ylabel="G(Δτ)"))
    else
        display(plot([0:length(tpcr[:,1])-1],tpcr[:,1],yerr=tpcr[:,2], label="⟨x₍ᵢ₊ⱼ₎xᵢ⟩ᵢ",xlabel="Δτ",ylabel="G(Δτ)"))
    end
    # plot!(tpcr[:,1],yerr=tpcr[:,2],yrange=[1.4*10^-3,10^2],yaxis=:log,title="Two-Point Correlation", label="⟨x₍ᵢ₊ₓ₎xᵢ⟩")
    return tpcr
end
function PlotTPCF(filename::AbstractString,Jackknife::Bool,logplot=true)
    tpcr = TPCF(filename,Jackknife)
    # println(tpcr[:,1])
    if logplot
        display(plot([0:length(tpcr[:,1])-1],tpcr[:,1],yerr=tpcr[:,2],yrange=[1.4*10^-3,10^2],yaxis=:log,label="⟨x₍ᵢ₊ₓ₎xᵢ⟩",xlabel="Δτ",ylabel="G(Δτ)"))
    else
        display(plot([0:length(tpcr[:,1])-1],tpcr[:,1],yerr=tpcr[:,2], label="⟨x₍ᵢ₊ⱼ₎xᵢ⟩ᵢ",xlabel="Δτ",ylabel="G(Δτ)"))
    end
    # SaveToFitGnu(filename)
    return tpcr
end
function PlotTPCF(filename::AbstractString,saveToFile::AbstractString)
    tpcr = TPCF(filename)
    SaveToFitGnu(saveToFile,tpcr)
end

"""
Save in format that can be used by Gnuplot for fit
"""
function SaveToFitGnu(saveToFile::AbstractString, tpcr)
    open(saveToFile,"a") do file
        for i = 1:length(tpcr[:,1])
            write(file,string(0.5*(i-1)," ",tpcr[i,1]," ",tpcr[i,2],"\n"))
        end
    end
    # file with "0.5*(i-1) tpcr[i,1] tpcr[i,2]\n" for each line
    # @gp """plot "results/Twopointdata.csv" u 1:2:3 w e"""
    # print("ok")
    # @gp """f(x)=a*cosh(b*(x-4))"""
    # @gp :- """fit f(x) "results/Twopointdata.csv" u 1:2:3 via a,b"""
end
# SaveToFitGnu("results/Twopointdata.csv")




"""
Plots the expected TPCF for a system
"""
function PlotTPCFe(a,m,ω,n_tau)
    plot([0:n_tau-1],TPCFe(a,m,ω,n_tau),label="TPC_exp")
end
function PlotTPCFe(a,m,ω,n_tau,FirstN::Integer)
    plot([0:FirstN-1],TPCFe(a,m,ω,n_tau)[1:FirstN],label="TPC_exp")
end
function PlotTPCFe(param)
    n_tau, a, m, μ = param.n_tau, param.a, param.m, param.μ
    ω = sqrt((μ/m))
    plot([0:n_tau-1],TPCFe(a,m,ω,n_tau),label="TPC_exp")
end
function PlotTPCFe(param,FirstN::Integer)
n_tau, a, m, μ = param.n_tau, param.a, param.m, param.μ
ω = sqrt((μ/m))
plot([0:FirstN-1],TPCFe(a,m,ω,n_tau)[1:FirstN],label="TPC_exp")
end

"""
Plots the expected TPCF for a system, appending to previous plot
"""
function PlotTPCFe!(a,m,ω,n_tau)
    plot!([0:n_tau-1],TPCFe(a,m,ω,n_tau),label="TPC_exp",linewidth=1)
end
function PlotTPCFe!(a,m,ω,n_tau,FirstN::Integer)
    plot!([0:FirstN-1],TPCFe(a,m,ω,n_tau)[1:FirstN],label="TPC_exp",linewidth=1)
end
function PlotTPCFe!(param)
    n_tau, a, m, μ = param.n_tau, param.a, param.m, param.μ
    ω = sqrt(μ/m)
    plot!([0:n_tau-1],TPCFe(a,m,ω,n_tau),label="TPC_exp")
end
function PlotTPCFe!(param,FirstN::Integer)
    n_tau, a, m, μ = param.n_tau, param.a, param.m, param.μ
    ω = sqrt(μ/m)
    plot!([0:FirstN-1],TPCFe(a,m,ω,n_tau)[1:FirstN],label="TPC_exp")
end

# title!("title") to get title on plots
# """
# Plots the Two-Point Correlation Function with title from file
# """
# function PlotTPCFwt(filename,logplot=true)
#     tpcr = Err1(GetTwoPointData(filename))
#     if logplot
#         display(plot(tpcr[:,1],yerr=tpcr[:,2],yrange=[1.4*10^-3,10^2],yaxis=:log,title="Two-Point Correlation", label="⟨x₍ᵢ₊ₓ₎xᵢ⟩",xlabel="Δτ",ylabel="G(Δτ)"))
#     else
#         display(plot(tpcr[:,1],yerr=tpcr[:,2],title="Two-Point Correlation", label="⟨x₍ᵢ₊ₓ₎xᵢ⟩",xlabel="Δτ",ylabel="G(Δτ)"))
#     end
#     # plot!(tpcr[:,1],yerr=tpcr[:,2],yrange=[1.4*10^-3,10^2],yaxis=:log,title="Two-Point Correlation", label="⟨x₍ᵢ₊ₓ₎xᵢ⟩")
#     return tpcr
# end
# function PlotTPCFwt(filename,Jackknife::Bool,logplot=true)
#     if Jackknife
#         tpcr = Jackknife1(GetTwoPointData(filename))
#     else
#         tpcr = Err1(GetTwoPointData(filename))
#     end
#     # println(tpcr[:,1])
#     if logplot
#         display(plot(tpcr[:,1],yerr=tpcr[:,2],yrange=[1.4*10^-3,10^2],yaxis=:log,title="Two-Point Correlation", label="⟨x₍ᵢ₊ₓ₎xᵢ⟩",xlabel="Δτ",ylabel="G(Δτ)"))
#     else
#         display(plot(tpcr[:,1],yerr=tpcr[:,2],title="Two-Point Correlation", label="⟨x₍ᵢ₊ₓ₎xᵢ⟩",xlabel="Δτ",ylabel="G(Δτ)"))
#     end
#     # open("results/Twopointdata.csv","a") do file
#     #     for i = 1:length(tpcr[:,1])
#     #         write(file,string(i/2-1/2," ",tpcr[i,1]," ",tpcr[i,2],"\n"))
#     #     end
#     # end
#     return tpcr
# end




#                                       #
#          Plot Effective Mass          #
#                                       #
"""
Plots the Effective Mass from TPCF data from file
"""
function PlotEffM(filename)
    tpcr = Err1(GetTwoPointData(filename))
    effm = EffM(tpcr)
    # effm = Matrix{Float64}(undef,length(tpcr[:,1])-2,1)
    # for i=2:length(tpcr[:,1])-1
    #     effm[i-1,1] = log10(tpcr[i-1,1]/tpcr[i+1,1])
    # end
    # effm./2
    display(plot(effm[:,1],yerr=effm[:,2],xlabel="Δτ",ylabel="mₑ(Δτ)"))
    return effm
end
function PlotEffM(filename,FirstN::Integer)
    tpcr = Err1(GetTwoPointData(filename)[:,1:FirstN])
    effm = EffM(tpcr)
    # effm = Matrix{Float64}(undef,length(tpcr[:,1])-2,1)
    # for i=2:length(tpcr[:,1])-1
    #     effm[i-1,1] = log10(tpcr[i-1,1]/tpcr[i+1,1])
    # end
    # effm./2
    display(plot(effm[:,1],yerr=effm[:,2],xlabel="Δτ",ylabel="mₑ(Δτ)"))
    return effm
end
# """
# Plots the Effective Mass from TPCF data from file
# """
# function PlotEffM(filename)
#     tpcr = GetTwoPointData(filename)
#     effm = EffM(tpcr)
#     # effm = Matrix{Float64}(undef,length(tpcr[:,1])-2,1)
#     # for i=2:length(tpcr[:,1])-1
#     #     effm[i-1,1] = log10(tpcr[i-1,1]/tpcr[i+1,1])
#     # end
#     # effm./2
#     display(plot(effm[:,1],yerr=effm[:,2],xlabel="Δτ",ylabel="mₑ(Δτ)"))
#     return effm
# end
# function PlotEffM(filename,FirstN::Integer)
#     tpcr = GetTwoPointData(filename)[:,1:FirstN]
#     effm = EffM(tpcr)
#     # effm = Matrix{Float64}(undef,length(tpcr[:,1])-2,1)
#     # for i=2:length(tpcr[:,1])-1
#     #     effm[i-1,1] = log10(tpcr[i-1,1]/tpcr[i+1,1])
#     # end
#     # effm./2
#     display(plot(effm[:,1],yerr=effm[:,2],xlabel="Δτ",ylabel="mₑ(Δτ)"))
#     return effm
# end
# function PlotEffM(filename,Jackknife::Bool)
#     tpcr = GetTwoPointData(filename)
#     if Jackknife
#         effm = EffM(tpcr,Jackknife)
#     else
#         effm = EffM(tpcr)
#     end
#     display(plot(effm[:,1],yerr=effm[:,2],xlabel="Δτ",ylabel="mₑ(Δτ)"))
#     return effm
# end




#                                       #
#   Plot Probability density diagram    #
#                                       #
"""
Plots Probability Density Diagram from data file, array or matrix 
"""
function PlotProbDD(filename::AbstractString)
    arr1 = GetData(filename,4,1)
    arr1 = reshape(arr1,:)
    histogram(arr1,bins=[i for i=floor(minimum(arr1)*10)/10:0.1:(floor(maximum(arr1)*10)+1)/10],normed=true,xlabel="x",ylabel="|ψ₀|²",legend=false)#,weights=repeat([1/length(arr1)],length(arr1))
end
function PlotProbDD(filename::AbstractString,incsize1)
    arr1 = GetData(filename,4,1)
    arr1 = reshape(arr1,:)
    histogram(arr1,bins=[i for i=floor(minimum(arr1)*10)/10:incsize1:(floor(maximum(arr1)*10)+1)/10],normed=true,xlabel="x",ylabel="|ψ₀|²",legend=false)#,weights=repeat([1/length(arr1)],length(arr1))
end
function PlotProbDD(array1::AbstractArray)
    array1 = reshape(array1,:)
    histogram(array1,bins=[i for i=floor(minimum(array1)*10)/10:0.1:(floor(maximum(array1)*10)+1)/10],normed=true,xlabel="x",ylabel="|ψ₀|²",legend=false)#,weights=repeat([1/length(arr1)],length(arr1))
end
function PlotProbDD(array1::AbstractArray,incsize1)
    array1 = reshape(array1,:)
    histogram(array1,bins=[i for i=floor(minimum(array1)*10)/10:incsize1:(floor(maximum(array1)*10)+1)/10],normed=true,xlabel="x",ylabel="|ψ₀|²",legend=false)#,weights=repeat([1/length(arr1)],length(arr1))
end
function PlotProbDD(matr1::AbstractMatrix)
    matr1 = reshape(matr1,:)
    histogram(matr1,bins=[i for i=floor(minimum(matr1)*10)/10:0.1:(floor(maximum(matr1)*10)+1)/10],normed=true,xlabel="x",ylabel="|ψ₀|²",legend=false)#,weights=repeat([1/length(arr1)],length(arr1))
end
function PlotProbDD(matr1::AbstractMatrix,incsize1)
    matr1 = reshape(matr1,:)
    histogram(matr1,bins=[i for i=floor(minimum(matr1)*10)/10:incsize1:(floor(maximum(matr1)*10)+1)/10],normed=true,xlabel="x",ylabel="|ψ₀|²",legend=false)#,weights=repeat([1/length(arr1)],length(arr1))
end

"""
Calculates the analytical Probability Density Diagram for the HO  
appends it to a plot  
"""
function PlotProbDDe(m,ω,ħ,range1)
    println("m = ",m,", ω = ",ω,", ħ = ",ħ)
    plot([x for x=-range1:0.01:range1],[((m*ω/(π*ħ))^(1/4)*exp(-m*ω*x^2/(2*ħ)))^2 for x=-range1:0.01:range1],linewidth=2)
end
function PlotProbDDe!(plt,m,ω,ħ,range1)
    println("m = ",m,", ω = ",ω,", ħ = ",ħ)
    plot!(plt,[x for x=-range1:0.01:range1],[((m*ω/(π*ħ))^(1/4)*exp(-m*ω*x^2/(2*ħ)))^2 for x=-range1:0.01:range1],linewidth=2)
end






#                                               #
#            Plotting mean of data              #
#                                               #
"""
Plots final expectationvalues  
n = 1: ⟨x̂ᵢ⟩  
n = 2: ⟨x̂ᵢ²⟩  
n = 3: ⟨x̂ᵢ⟩, ⟨x̂ᵢ²⟩
"""
function PlotExp(exp,n)
    if n == 1
        title = "Expectationvalue x"
        label = "⟨xᵢ⟩"
    elseif n == 2
        title = "Expectationvalue x²"
        label = "⟨(xᵢ)²⟩"
    elseif n == 3
        title = "Expectationvalue x, x²"
        label = ["⟨xᵢ⟩" "⟨(xᵢ)²⟩"]
        println("Plot?")
        println("Plotted?")
    else
        hline([0,mean(exp)])
        println("n != {1, 2, 3}")
        return 1
    end
    plot!(exp, title=title, label=label)
    # plot([1:length(exp),exp], title=title, label=label)
end

"""
Plots running expectationvalues of x₁ or those in array "number"  
n = 1: ⟨x̂ᵢ⟩  
n = 2: ⟨x̂ᵢ²⟩  
n = 3: ⟨x₁xᵢ⟩
"""
function plot_x(meanf)
    matrixData = GetColumn(2,meanf)
    plot(matrixData[:,1],label="⟨x⟩ₘₑₐ")
    return
end
function plot_x(meanf, n)
    matrixData = GetExpXData(meanf,n)
    plot(matrixData[:,1],label="⟨x⟩ₘₑₐ")
    return
end
function plot_x(meanf, n, number)
    matrixData = GetExpXData(meanf, n, number)
    labl = ""
    if n == 1
        labl = "⟩ₘₑₐ"
    elseif n == 2
        labl = "²⟩ₘₑₐ"
    else
        labl = "x₁⟩ₘₑₐ"
    end
    plot(matrixData[:,1], label=string("⟨x_$(number[1])",labl))
    for (i,val) = enumerate(number[2:length(number)])
        println(i+1)
        plot!(matrixData[:,i+1], label=string("⟨x_$(val)",labl))
    end
    return
end
function plot_x(meanf, n, number::Number)
    matrixData = GetExpXData(meanf, n, number)
    labl = ""
    if n == 1
        labl = "⟩ₘₑₐ"
    elseif n == 2
        labl = "²⟩ₘₑₐ"
    else
        labl = "x₁⟩ₘₑₐ"
    end
    plot(matrixData, label=string("⟨x_$(number)",labl))
    return
end


