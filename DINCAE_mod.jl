module DINCAE_mod
using Base.Threads
using CUDA
using Dates
using Random
using NCDatasets
using Printf
using Statistics
using ThreadsX
#using Knet
using ChainRulesCore
using Base.Iterators

import Base: length
import Base: size
import Base: getindex
import Random: shuffle!

using Profile

#import Knet: KnetArray, AutoGrad
#import Knet

#include("knet.jl")
include("flux.jl")
include("types.jl")
include("data_mod.jl")
include("model_mod.jl")
include("points_mod.jl")
include("vector2.jl")
end
