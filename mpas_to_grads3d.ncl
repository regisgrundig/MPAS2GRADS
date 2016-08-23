load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

   ;
   ; Whether to generate remapping weight files, or 
   ;   to actually regrid fields
   ;
   gen_weights = False 

   ;
   ;... read input MPAS files:
   ;
   files = systemfunc("ls history.*.nc")
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
   mpas3 = f[:]->uReconstructZonal
   mpas4 = f[:]->uReconstructMeridional
  




   dims = dimsizes(mpas4)
   rank = dimsizes(dims)

   print ("dims ="+dims);
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
   if (rank .eq. 3) then
      mpas3_reorder = mpas3(Time|:,nVertLevels|:,nCells|:)
      mpas4_reorder = mpas4(Time|:,nVertLevels|:,nCells|:)
   else
      mpas3_reorder = mpas3
      mpas4_reorder = mpas4
   end if
   delete(mpas3)
   delete(mpas4)

   if (gen_weights) then

      print("Generating remapping weights...")

      if (rank .eq. 3) then
         mpas3_regrid = ESMF_regrid(mpas3_reorder(0,:,:),opt)
         mpas4_regrid = ESMF_regrid(mpas4_reorder(0,:,:),opt)
      else
         mpas3_regrid = ESMF_regrid(mpas3_reorder(0,:),opt)
         mpas4_regrid = ESMF_regrid(mpas4_reorder(0,:),opt)
      end if

   else

      print("Remapping fields...")

      mpas3_regrid = ESMF_regrid_with_weights(mpas3_reorder,opt@WgtFileName,False)
      mpas4_regrid = ESMF_regrid_with_weights(mpas4_reorder,opt@WgtFileName,False)
      dims = dimsizes(mpas4_regrid)
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
      fout  = addfile ("latlon3d.nc", "c")

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
      if (rank .eq. 4) then
         filevardef(fout,"uReconstructZonal",typeof(mpas3_regrid),(/"Time","levels","lat","lon"/))
         filevardef(fout,"uReconstructMeridional",typeof(mpas4_regrid),(/"Time","levels","lat","lon"/))
      else
         filevardef(fout,"uReconstructZonal",typeof(mpas3_regrid),(/"Time","lat","lon"/))
         filevardef(fout,"uReconstructMeridional",typeof(mpas4_regrid),(/"Time","lat","lon"/))
      end if

      ;
      ;... output data:
      ;
      fout->latitude  = (/lat/)
      fout->longitude = (/lon/)
      fout->uReconstructZonal = (/mpas3_regrid/)
      fout->uReconstructMeridional = (/mpas4_regrid/)

   end if

end
