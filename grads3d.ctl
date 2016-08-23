dset ^latlon3d.nc
title xxx
undef 9.999e+20
dtype netcdf
xdef 361 linear 0 1
ydef 181 linear -90 1
zdef 41   linear 1 41 
tdef 33 linear  06Z01JAN1981 1dy
vars 2
uReconstructZonal=>u      41 t,z,y,x  vento 
uReconstructMeridional=>v 41 t,z,y,x  iventooo
endvars 
