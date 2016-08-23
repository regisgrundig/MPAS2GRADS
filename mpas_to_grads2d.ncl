load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

   ;
   ; Whether to generate remapping weight files, or 
   ;   to actually regrid fields
   ;
   gen_weights =  False 

   ;
   ;... read input MPAS files:
   ;
   files = systemfunc("ls ../06_MPAS/GERAR_CLIMA*.nc")
   f = addfiles(files,"r")

   ;
   ;... get lat/lon coordinates from first input file
   ;
   r2d  = 180.0d/(atan(1)*4.0d) ; conversion from radians to degrees.
   lonCellSrc = f[0]->lonCell * r2d
   latCellSrc = f[0]->latCell * r2d

   ;
   ;... interpolation to 1-deg latitude-longitude grid:
   ;
   opt = True
   opt@ForceOverwrite = True
   opt@SrcGridLon = lonCellSrc ; source grid lon input.
   opt@SrcGridLat = latCellSrc ; source grid lat input.
   opt@SrcGridType = "unstructured"
   opt@DstGridType = "1.0x1.0" ; destination grid
   opt@DstLLCorner = (/-89.50d, -179.50d /)
   opt@DstURCorner = (/ 89.50d,  179.50d /)
   opt@DstLLCorner = (/-90.00d, -180.00d /)
   opt@DstURCorner = (/ 90.00d,  180.00d /)
   opt@SrcFileName = "src_grid.nc"
   opt@DstFileName = "dst_grid.nc"
   opt@WgtFileName = "weights.nc"

   ;
   ;... get dimension sizes and predefine the coordinate variables and their dimensionality:
   ;
   ;
   mpas1= f[:]->sst
   mpas2 = f[:]->surface_pressure
   mpas3 = f[:]->t2m
   mpas4 = f[:]->lh
   mpas5 = f[:]->rainnc
   mpas6 = f[:]->rainc
   mpas7 = f[:]->hpbl

   dims = dimsizes(mpas1)
   rank = dimsizes(dims)
   nTime   = dims(0)
   nCells  = dims(1)
   if (rank .eq. 3) then
      nLevels = dims(2)
   end if
   print("nTime   = "+nTime  )
   print("nCells  = "+nCells )
   if (rank .eq. 3) then
      print("nLevels = "+nLevels)
   end if
   print("          ")
   delete(dims)

   ; 3-d fields need to have the nCells and nVertLevels dimensions swapped
      mpas1_reorder = mpas1
      mpas2_reorder = mpas2
      mpas3_reorder = mpas3
      mpas4_reorder = mpas4
      mpas5_reorder = mpas5
      mpas6_reorder = mpas6
      mpas7_reorder = mpas6
   delete(mpas1)
   delete(mpas2)
   delete(mpas3)
   delete(mpas4)
   delete(mpas5)
   delete(mpas6)
   delete(mpas7)

   if (gen_weights) then

      print("Generating remapping weights...")

         mpas1_regrid = ESMF_regrid(mpas1_reorder(0,:),opt)
         mpas2_regrid = ESMF_regrid(mpas2_reorder(0,:),opt)
         mpas3_regrid = ESMF_regrid(mpas3_reorder(0,:),opt)
         mpas4_regrid = ESMF_regrid(mpas4_reorder(0,:),opt)
         mpas5_regrid = ESMF_regrid(mpas5_reorder(0,:),opt)
         mpas6_regrid = ESMF_regrid(mpas6_reorder(0,:),opt)
         mpas7_regrid = ESMF_regrid(mpas6_reorder(0,:),opt)

   else

      print("Remapping fields...")

      mpas1_regrid = ESMF_regrid_with_weights(mpas1_reorder,opt@WgtFileName,False)
      mpas2_regrid = ESMF_regrid_with_weights(mpas2_reorder,opt@WgtFileName,False)
      mpas3_regrid = ESMF_regrid_with_weights(mpas3_reorder,opt@WgtFileName,False)
      mpas4_regrid = ESMF_regrid_with_weights(mpas4_reorder,opt@WgtFileName,False)
      mpas5_regrid = ESMF_regrid_with_weights(mpas5_reorder,opt@WgtFileName,False)
      mpas6_regrid = ESMF_regrid_with_weights(mpas6_reorder,opt@WgtFileName,False)
      mpas7_regrid = ESMF_regrid_with_weights(mpas7_reorder,opt@WgtFileName,False)
      dims = dimsizes(mpas1_regrid)
      rank = dimsizes(dims)

      print(dims)
      nTime   = dims(0)
      print("nTime   = "+nTime)
      if (rank .eq. 4) then
         nLevels = dims(1)
         nLat    = dims(2)
         nLon    = dims(3)
         print("nLevels = "+nLevels)
      else
         nLat    = dims(1)
         nLon    = dims(2)
      end if
      print("nLat    = "+nLat )
      print("nLon    = "+nLon )

      ;
      ;... open output NetCDF file
      ;
      fout  = addfile ("latlon2.nc", "c")

      if (rank .eq. 4) then
         dimNames = (/"Time", "lat" , "lon" , "levels"/)
         dimSizes = (/-1    , nLat  , nLon  , nLevels /)
         dimUnlim = (/True  , False , False , False   /)
      else
         dimNames = (/"Time", "lat" , "lon"/)
         dimSizes = (/-1    , nLat  , nLon/)
         dimUnlim = (/True  , False , False/)
      end if
      filedimdef(fout,dimNames,dimSizes,dimUnlim)

      lat = fspan(-90.00d,90.00d,nLat)
      lon = fspan(-180.00d,180.00,nLon)

      ;
      ;copy global atttibutes from the input to the output file:
      ;
      fileattdef(fout,f[0])

      ;
      ;... predefine the dimensionality of the variables to be written out:
      ;
      filevardef(fout,"latitude" ,typeof(lat)  ,(/"lat"/))
      filevardef(fout,"longitude",typeof(lon)  ,(/"lon"/))
         filevardef(fout,"sst",typeof(mpas1_regrid),(/"Time","lat","lon"/))
         filevardef(fout,"surface_pressure",typeof(mpas2_regrid),(/"Time","lat","lon"/))
         filevardef(fout,"t2m",typeof(mpas3_regrid),(/"Time","lat","lon"/))
         filevardef(fout,"lh",typeof(mpas4_regrid),(/"Time","lat","lon"/))
         filevardef(fout,"rainnc",typeof(mpas5_regrid),(/"Time","lat","lon"/))
         filevardef(fout,"rainc",typeof(mpas6_regrid),(/"Time","lat","lon"/))
         filevardef(fout,"hpbl",typeof(mpas7_regrid),(/"Time","lat","lon"/))

      ;
      ;... output data:
      ;
      fout->latitude  = (/lat/)
      fout->longitude = (/lon/)
      fout->sst = (/mpas1_regrid/)
      fout->surface_pressure = (/mpas2_regrid/)
      fout->t2m = (/mpas3_regrid/)
      fout->lh = (/mpas4_regrid/)
      fout->rainnc = (/mpas5_regrid/)
      fout->rainc = (/mpas6_regrid/)
      fout->hpbl = (/mpas7_regrid/)

   end if

end
