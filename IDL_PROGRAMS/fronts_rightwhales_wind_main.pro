; $ID:	FRONTS_RIGHTWHALES_WIND_MAIN.PRO,	2022-01-27-15,	USER-KJWH	$
  PRO FRONTS_RIGHTWHALES_WIND_MAIN

;+
; NAME:
;   FRONTS_RIGHTWHALES_WIND_MAIN
;
; PURPOSE:
;   Create frontal data and visualizations for the Right Whale Wind project
;
; PROJECT:
;   READ-EDAB-FRONTS
;
; CALLING SEQUENCE:
;   Result = FRONTS_RIGHTWHALES_WIND_MAIN($Parameter1$, $Parameter2$, $Keyword=Keyword$, ...)
;
; REQUIRED INPUTS:
;   Parm1.......... Describe the positional input parameters here. 
;
; OPTIONAL INPUTS:
;   Parm2.......... Describe optional inputs here. If none, delete this section.
;
; KEYWORD PARAMETERS:
;   KEY1........... Document keyword parameters like this. Note that the keyword is shown in ALL CAPS!
;
; OUTPUTS:
;   OUTPUT.......... Decribe the output of this program or function
;
; OPTIONAL OUTPUTS:
;   None
;
; COMMON BLOCKS: 
;   None
;
; SIDE EFFECTS:  
;   None
;
; RESTRICTIONS:  
;   None
;
; EXAMPLE:
; 
;
; NOTES:
;   $Citations or any other useful notes$
;   
; COPYRIGHT: 
; Copyright (C) 2022, Department of Commerce, National Oceanic and Atmospheric Administration, National Marine Fisheries Service,
;   Northeast Fisheries Science Center, Narragansett Laboratory.
;   This software may be used, copied, or redistributed as long as it is not sold and this copyright notice is reproduced on each copy made.
;   This routine is provided AS IS without any express or implied warranties whatsoever.
;
; AUTHOR:
;   This program was written on January 27, 2022 by Kimberly J. W. Hyde, Northeast Fisheries Science Center | NOAA Fisheries | U.S. Department of Commerce, 28 Tarzwell Dr, Narragansett, RI 02882
;    
; MODIFICATION HISTORY:
;   Jan 27, 2022 - KJWH: Initial code written
;-
; ****************************************************************************************************
  ROUTINE_NAME = 'FRONTS_RIGHTWHALES_WIND_MAIN'
  COMPILE_OPT IDL2
  SL = PATH_SEP()
  
  DIR_PRO = !S.READ_EDAB_FRONTS + 'WIND/RIGHT_WHALES/'
  
  MERGE_FRONTS=0
  BATCH_PARALLEL=0
  CLIM_STATS=0
  NETCDFS=0
  PNGS=0
  COMPOSITE=1
  
  DATASET = 'AT'
  PRODS = ['GRAD_SST-BOA','GRAD_CHL-BOA']
  DATERANGE = ['2010','2020']
  NCMAP = 'NESGRID2'
  PLTMAP = 'SNEGRID'
  
  SHPS = ['BOEM_MA_RI_LEASES', 'Mayflower_Wind_Lease','WTG_OSP_Locations']
  CFILES = []
  FOR R=0, N_ELEMENTS(PRODS)-1 DO BEGIN
    APROD = PRODS[R]
    DIR_STATS = DIR_PRO + 'STATS' + SL + APROD + SL
    DIR_NETCDF = DIR_PRO + 'NETCDF' + SL + APROD + SL
    DIR_PNGS = DIR_PRO + 'PNGS' + SL + APROD + SL
    DIR_TEST,[DIR_STATS,DIR_NETCDF,DIR_PNGS]
     
    IF KEYWORD_SET(MERGE_FRONTS) THEN SAVE_FRONT_MERGE, DATASET, PRODS=APROD, DATERANGE=DATERANGE
    
    CMD = "BATCH_L3, DO_STAT_FRONTS='Y["+DATASET+";P="+APROD+";PER=M]',BATCH_DATASET='"+DATASET+"',BATCH_DATERANGE='"+STRJOIN(DATERANGE,'_')+"'"
    IF KEYWORD_SET(BATCH_PARALLEL) THEN BATCH_L3_PARALLEL, CMD, NPROCESS=8, SERVERS=['satdata'], IDL88=0, R_YEAR=0, SPWN=SPWN
     
    FILES = GET_FILES(DATASET, PRODS=APROD, PERIOD='M', DATERANGE=DATERANGE)
    FILE_LABEL=FILE_LABEL_MAKE(FILES[0], LST=['SENSOR','SATELLITE','COVERAGE','SAT_EXTRA',  'METHOD','MAP','PROD','ALG'])
    IF KEYWORD_SET(CLIM_STATS) THEN STATS_ARRAYS_FRONTS, FILES, DIR_OUT=DIR_STATS, PERIOD_CODE_OUT='MONTH', FILE_LABEL=FILE_LABEL, DO_STATS=STAT_TYPES, REVERSE_FILES=R_FILES, OVERWRITE=OVERWRITE, VERBOSE=VERBOSE, LOGLUN=LOGLUN;, /THUMBNAILS

    SFILES = FILE_SEARCH(DIR_STATS + 'MONTH*.SAV')
    
    IF KEYWORD_SET(NETCDF) THEN WRITE_NETCDF,SFILES,DIR_OUT=DIR_NETCDF,MAP_OUT=NCMAP,TAGS_STAT=['NUM','MEAN','STD'],NC_SUITE='FRONTS',OVERWRITE=OVERWRITE,VERBOSE=VERBOSE,OUTFILES=OUTFILES

    IF KEYWORD_SET(PNGS) THEN BEGIN
      FOR S=0, N_ELEMENTS(SHPS)-1 DO BEGIN
        SFILES = FILE_SEARCH(DIR_STATS + 'MONTH*.SAV')
        SHP = READ_SHPFILE(SHPS[S],MAPP=PLTMAP)
        IF STRUCT_HAS(SHP,'OUTLINE') THEN OUTLINE=SHP.OUTLINE ELSE OUTLINE = SHP.POINTS
        PRODS_2PNG, SFILES, MAPP=PLTMAP, OUTLINE=OUTLINE,/ADD_OUTLINE, OUT_THICK=1, OUT_COLOR=0, DIR_OUT=DIR_PNGS, /BUFFER  
        PFILES = FILE_SEARCH(DIR_PNGS + 'MONTH*' + APROD + '*STATS.PNG')
        FILE_RENAME, PFILES, NAME_CHANGE=['STATS','STATS-'+SHPS[S]]  
      ENDFOR
    ENDIF
      
    CFILES = [CFILES,SFILES]  
  ENDFOR  
  
  IF KEYWORD_SET(COMPOSITE) THEN BEGIN
    FOR S=0, N_ELEMENTS(SHPS)-1 DO BEGIN
      SHP = READ_SHPFILE(SHPS[S],MAPP=PLTMAP)
      IF STRUCT_HAS(SHP,'OUTLINE') THEN OUTLINE=SHP.OUTLINE ELSE OUTLINE = SHP.POINTS
    
      COMPFILE = DIR_PRO + 'PNGS' + SL + 'MONTHLY_CLIMATOLOGY-GRAD_SST-GRAD_CHL-'+SHPS[S]+'.PNG'
      IF ~FILE_MAKE(CFILES,COMPFILE,OVERWRITE=OVERWRITE) THEN CONTINUE
          
      NCOLS = 12  & NROWS = 2
      XDIM  = 150 & YDIM  = 115
      SPACE  = 10
      LEFT   = SPACE * 3
      RIGHT  = SPACE * 10
      TOP    = SPACE * 4
      BOTTOM = SPACE * 3
      
      IMG_PRODS  = ['GRAD_SST_0.01_0.6','GRAD_CHL_1_1.1']
      CBTICKS = LIST(['0.01','0.03','0.1','0.3','0.6'],['1.0','1.03','1.06','1.1'])
      ROW_TITLES = ['SST','CHL']
      COL_TITLES = STRUPCASE(MONTH_NAMES(/SHORT))
      CB_TITLES = UNITS(PRODS)
      
      XNSPACE = NCOLS-1 & YNSPACE = NROWS-1
      WIDTH   = LEFT   + NCOLS*XDIM + XNSPACE*SPACE + RIGHT
      HEIGHT  = BOTTOM + NROWS*YDIM + YNSPACE*SPACE + TOP
      
      WIMG = WINDOW(DIMENSIONS=[WIDTH,HEIGHT],BUFFER=BUFFER)
      COUNTER=0
      FOR W=0, NROWS-1 DO BEGIN
        CTITLE = ROW_TITLES[W]
        IMGPROD = IMG_PRODS[W]
        CBTITLE = UNITS(PRODS[W],/NO_UNIT)+'!C'+UNITS(PRODS[W],/NO_NAME)
        FOR L=0, NCOLS-1 DO BEGIN
          RTITLE = COL_TITLES[L]
          C = COUNTER MOD NCOLS           ; Number of columns is associated with the number of months so C represents the column number
          XPOS = LEFT + C*XDIM + C*SPACE  ; Determine the left side of the image
          IF C EQ 0 THEN R = COUNTER/NCOLS ELSE R = W ; When C = 0, start a new row
          IF L EQ 0 THEN YPOS = HEIGHT - TOP - R*YDIM - R*SPACE ELSE YPOS = YPOS ; Determine the top position of the image
          POS = [XPOS,YPOS-YDIM,XPOS+XDIM,YPOS]
    
          IF W EQ 0 THEN TMT = TEXT(POS[0]+XDIM/2,POS[3]+5,RTITLE,ALIGNMENT=0.5,FONT_STYLE='BOLD',FONT_SIZE=FONT_SIZE,/DEVICE) ; Add month name to the image
          IF L EQ 0 THEN TYR = TEXT(LEFT/2,POS[1]+YDIM/2,  CTITLE,ALIGNMENT=0.5,FONT_STYLE='BOLD',FONT_SIZE=FONT_SIZE,/DEVICE,VERTICAL_ALIGNMENT=0.5,ORIENTATION=90) ; Add year to the image
    
          PRODS_2PNG, CFILES[COUNTER], PROD=IMGPROD, ADD_CB=0, PAL=PAL, IMG_POS=POS, MAPP=PLTMAP, DEPTH=BATHY_DEPTHS, OUTLINE=OUTLINE, OUT_COLOR=0, MASK=MASK, OUT_THICK=2, /CURRENT, /DEVICE, BUFFER=BUFFER
          IF ANY(IMG_TITLES) THEN TXT = TEXT(XPOS+5,YPOS-5,IMG_TITLES[COUNTER],FONT_SIZE=FONT_SIZE,FONT_STYLE=FONT_STYLE,VERTICAL_ALIGNMENT=1,/DEVICE)
          COUNTER = COUNTER + 1
          
        ENDFOR ; ROWS
        CBPOS = [POS[2]+SPACE, POS[1], POS[2]+SPACE*2,POS[3]]
        CBPOS = CBPOS/FLOAT([WIDTH,HEIGHT,WIDTH,HEIGHT])
        CBAR, IMGPROD, OBJ=WIMG, FONT_SIZE=10, FONT_STYLE=FONT_STYLE, CB_TYPE=5, CB_POS=CBPOS, CB_TICKNAMES=CBTICKS[W],CB_TITLE=CBTITLE, PAL=PAL
      ENDFOR ; COLS
      
      WIMG.SAVE, COMPFILE
      WIMG.CLOSE
    ENDFOR  
  ENDIF  
           


END ; ***************** End of FRONTS_RIGHTWHALES_WIND_MAIN *****************
