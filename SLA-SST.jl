using Pkg
#Pkg.activate("/file/path/") # needs to be repeated for every session
Pkg.instantiate() # install all package


Pkg.add(["CUDA","Knet","NCDatasets","PyPlot", "PyCall", "ChainRulesCore", "ThreadsX", "Flux","Distributions","GeoDatasets", "Glob", "JSON", "LinearAlgebra", "Interpolations"])
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

# Set directory
localdir = pwd()

# filename of the clean data
filename = joinpath(localdir,"subset-sla-train.nc")
# filename of the data with added clouds for cross-validation
filename_cv = joinpath(localdir,"subset-sla-train_add_clouds.nc")
varname = "sla";
auxdata_files = [
  (filename = joinpath(localdir,"subset-sst.nc"),
   varname = "SST",
   errvarname = "SST_error")]
# Results of DINCAE will be placed in a sub-directory under `localdir`
outdir = joinpath(localdir,"Results")
mkpath(outdir)

# ## Data preparation
# Load the NetCDF variables

ds = NCDataset(filename)
close(ds)

# Add a land-sea mask to the file. Grid points with less than 5% of valid data are considered as land.

#DINCAE_utils_mod.add_mask(filename,varname; minseafrac = 0.05)

# Choose cross-validation points by adding clouds to the cleanest images (copied from the cloudiest images). This function will generate a file `fname_cv`.

#DINCAE_utils_mod.addcvpoint(filename,varname; mincvfrac = 0.10);

##Reconstruct missing data
# F is the floating point number type for the neural network. Here we use single precision.
const F = Float32

# Test if CUDA is functional to use the GPU, otherwise the CPU is used.
if CUDA.functional()
    Atype = KnetArray{F}
else
    @warn "No supported GPU found. We will use the CPU which is very slow. Please check https://developer.nvidia.com/cuda-gpus"
    Atype = Array{F}
end

Knet.atype() = Atype

# Setting the parameters of neural network.
# See the documentation of `DINCAE.reconstruct` for more information.
Δlon = 0.25
Δlat = 0.25
lonr = -7 : Δlon : 37
latr = 29 : Δlat : 46
grid = (lonr,latr)

epochs = 2
batch_size = 32
clip_grad = 5.0
jitter_std_pos = (0.17145703272237467f0,0.17145703272237467f0)
learning_rate_decay_epoch = 50
save_epochs = [epochs]
savesnapshot = true
nfilter_inc = 25
ndepth = 3
ntime_win = 27
learning_rate = 0.000579728
probability_skip_for_training = 0.877079
seed = 12345
upsampling_method = :nearest
start_skip = 2
regularization_L1_beta = 0
regularization_L2_beta = 1e-4
loss_weights_refine = (1.,)
enc_nfilter_internal = [25,50,75]
skipconnections = start_skip:(length(enc_nfilter_internal)+1)

fnames_rec = [joinpath(outdir,"data-avg.nc")]


# Use these parameters for a quick test:

epochs =5
save_epochs = epochs:epochs

# Start the training and reconstruction of the neural network.

loss = DINCAE_mod.reconstruct_points(
   F,Atype,filename,varname,grid,fnames_rec;
    learning_rate = learning_rate,
    learning_rate_decay_epoch = learning_rate_decay_epoch,
    epochs = epochs,
    batch_size = batch_size,
    enc_nfilter_internal = enc_nfilter_internal,
    skipconnections = skipconnections,
    clip_grad = clip_grad,
    save_epochs = save_epochs,
    upsampling_method = upsampling_method,
    jitter_std_pos = jitter_std_pos,
    probability_skip_for_training = probability_skip_for_training,
    auxdata_files = auxdata_files,
    ntime_win = ntime_win,
    savesnapshot = savesnapshot,
    regularization_L1_beta = regularization_L1_beta,
    regularization_L2_beta = regularization_L2_beta,
    loss_weights_refine = loss_weights_refine,
)

