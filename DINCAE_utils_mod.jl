module DINCAE_utils_mod

using Dates
using Distributions
using GeoDatasets
using Glob
using JSON
using LinearAlgebra
using NCDatasets
using Printf
using PyPlot
using PyCall
using PyCall: PyObject
using Random
using Statistics
using Interpolations

include("DINCAE_mod.jl")
include("dataprep.jl")
include("plots.jl")
include("validation.jl")

end # module
