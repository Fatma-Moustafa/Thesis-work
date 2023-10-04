using Pkg
#Pkg.activate("/file/path/") # needs to be repeated for every session
#Pkg.instantiate() # install all package


Pkg.add(["CUDA","NCDatasets","PyPlot","Plots", "PyCall", "ChainRulesCore", "ThreadsX", "Flux","Distributions","GeoDatasets", "Glob", "JSON", "LinearAlgebra", "Interpolations", "Random"])
include("DINCAE_mod.jl")
include("DINCAE_utils_mod.jl")
# Load the necessary modules

using CUDA
using PyCall
using Dates
using Knet
using NCDatasets
#using DINCAE_mod
#using DINCAE_utils_mod
using PyPlot
using Plots

# Set directory
localdir = pwd()

# filename of the clean data
fname = joinpath(localdir,"chl22.nc")
# filename of the data with added clouds for cross-validation
fname_cv = joinpath(localdir,"chl22_add_clouds.nc")
varname = "CHL"

auxdata_files = [
  (filename = joinpath(localdir,"sst22.nc"),
   varname = "analysed_sst",
   errvarname = "analysis_error")]
# Results of DINCAE will be placed in a sub-directory under `localdir`
outdir = joinpath(localdir,"Results")
mkpath(outdir)

# ## Data preparation
# Load the NetCDF variables

ds = NCDataset(fname)
close(ds)

# Add a land-sea mask to the file. Grid points with less than 5% of valid data are considered as land.

DINCAE_utils_mod.add_mask(fname,varname; minseafrac = 0.05)

# Choose cross-validation points by adding clouds to the cleanest images (copied from the cloudiest images). This function will generate a file `fname_cv`.

DINCAE_utils_mod.addcvpoint(fname,varname; mincvfrac = 0.10);

##Reconstruct missing data
# F is the floating point number type for the neural network. Here we use single precision.
const F = Float32

# Test if CUDA is functional to use the GPU, otherwise the CPU is used.
if CUDA.functional()
    #Atype = KnetArray{F}
    Atype = CuArray{F}
else
    @warn "No supported GPU found. We will use the CPU which is very slow. Please check https://developer.nvidia.com/cuda-gpus"
    Atype = Array{F}
end

#Knet.atype() = Atype

# Setting the parameters of neural network.
# See the documentation of `DINCAE.reconstruct` for more information.

# Use these parameters for a quick test:
epochs = 5
batch_size = 5
save_each = 10
skipconnections = [1,2]
enc_nfilter_internal = round.(Int,32 * 2 .^ (0:3))
clip_grad = 5.0
regularization_L2_beta = 0
save_epochs = [epochs]
is3D = false
ntime_win = 3
upsampling_method = :nearest
truth_uncertain = false
loss_weights_refine = (0.3,0.7)

data = [
   (filename = fname_cv,
    varname = varname,
    obs_err_std = 1,
    jitter_std = 0.05,
    isoutput = true,
   )
]
data_test = data;
fnames_rec = [joinpath(outdir,"data-avg.nc")]
data_all = [data,data_test]

# Start the training and reconstruction of the neural network.

loss = DINCAE_mod.reconstruct(
    F,Atype,data_all,fnames_rec;
    epochs = epochs,
    batch_size = batch_size,
    truth_uncertain = truth_uncertain,
    enc_nfilter_internal = enc_nfilter_internal,
    clip_grad = clip_grad,
    save_epochs = save_epochs,
    is3D = is3D,
    upsampling_method = upsampling_method,
    ntime_win = ntime_win,
    loss_weights_refine = loss_weights_refine,
  

)

# Plot the loss function

fig = plot(loss)
ylim(extrema(loss[2:end]))
xlabel("epochs")
ylabel("loss");
display(fig)
# # Post process results
# Compute the RMS (Root Mean Squared error) with the independent validation data

case = (
    fname_orig = fname,
    fname_cv = fname_cv,
    varname = varname,
)
fnameavg = joinpath(outdir,"data-avg.nc")
cvrms = DINCAE_utils_mod.cvrms(case,fnameavg)
@info "Cross-validation RMS error is: $cvrms"

# Next we plot all time instances. The figures will be placed in the directory `figdir`

figdir = joinpath(outdir,"Fig")
DINCAE_utils_mod.plotres(case,fnameavg, clim = nothing, figdir = figdir,
                     clim_quantile = (0.01,0.99),
                     which_plot = :cv)
@info "Figures are in $(figdir)"


# Example reconstruction for 2001-09-12
# ![reconstruction for the 2001-09-12](Fig/data-avg_2001-09-12.png)
# Panel (a) is the original data where we have added clouds (panel (b)). The
# reconstuction based on the data in panel (b) is shown in panel (c) together
# with its expected standard deviation error (panel (d)).