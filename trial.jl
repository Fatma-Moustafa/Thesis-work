Δlon = 0.5
Δlat = 0.5
lonr = 1: Δlon :2
latr =1: Δlat : 3
grid = (lonr,latr)
dates = 
a = length.(grid)
lengthdates = 2
lengthofAUX= 48
T= Float32
sz= length.(grid)...,lengthdates

auxx= zeros(T,(2*lengthofAUX))
kat= [1 1 1 1 1; 2 2 2 2 2; 3 3 3 3 3;;; 4 4 4 4 4; 5 5 5 5 5; 6 6 6 6 6;;;; 7 7 7 7 7; 8 8 8 8 8; 9 9 9 9 9;;; 10 10 10 10 10;11 11 11 11 11; 12 12 12 12 12]
println(auxx[:,1])
