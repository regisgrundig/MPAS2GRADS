dset ^mpasgrads.nc
title xxx
undef 9.999e+20
dtype netcdf
xdef 361 linear -180 1
ydef 181 linear -90 1
zdef 1   linear 1 1 
tdef 90 linear  06Z01JAN1981 1dy
vars 7
sst 0 t,y,x  sea surface temperature
sp 0 t,y,x  surface pressure
t2m 0 t,y,x  temperature at 2 meters
lh 0 t,y,x  leaft heat
rainnc 0 t,y,x  rain from microphysics
rainc 0 t,y,x  rain from convective
hpbl 0 t,y,x   hight pbl 
endvars 
