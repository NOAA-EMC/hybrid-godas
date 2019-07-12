#!/bin/bash
set -e

# This is a script file that generates the main input.nml file required by MOM for forecast runs.
# The following environment variables need to be set by the caller:
#  FCST_START_TIME   start date in YYYYMMDDHH format
#  FCST_RESTART      1 if starting from a restart, otherwise 0
#  FCST_LEN          integration length, in hours
#  FCST_RST_OFST     time (hours) from beginning of forecast until when restart file is to be saved.

restart='n'
if [[ "$FCST_RESTART" == 1 ]]; then restart='r'; fi


cat <<EOF

 &MOM_input_nml
         output_directory = 'OUTPUT',
         input_filename = '$restart'
         restart_input_dir = 'RESTART_IN',
         restart_output_dir = 'RESTART',
         parameter_filename = 'MOM_input',
                              'MOM_layout',
                              'MOM_saltrestore',
                              'MOM_override'
/

 &SIS_input_nml
        output_directory = 'OUTPUT',
        input_filename = '$restart'
        restart_input_dir = 'RESTART_IN',
        restart_output_dir = 'RESTART',
        parameter_filename = 'SIS_input',
                             'SIS_layout',
                             'SIS_override' /

 &atmos_model_nml
           layout = 0, 0
/

 &coupler_nml
            months = 0,
            days   = 0,
            hours  = $FCST_LEN,
            current_date = $(date "+%Y,%m,%d,%H" -d "${FCST_START_TIME:0:8}Z${FCST_START_TIME:8:10}"),0,0,
            calendar = 'julian', !< NOTE: an OVERRIDE of default OM4_025 settings
            dt_cpld = 1800,
            dt_atmos = 1800,
            do_atmos = .false.,
            do_land = .false.,
            do_ice = .true.,
            do_ocean = .true.,
            do_flux = .true.,
            atmos_npes = 0, 
            concurrent = .false.     
            use_lag_fluxes=.false.    
            check_stocks = 0
            do_endpoint_chksum=.false.
            restart_interval=0,0,0,${FCST_RST_OFST},0 !< NOTE: not in default OM4_025 settings
/

 &diag_manager_nml
            max_axes = 100,
            max_files = 63,
            max_num_axis_sets = 100,
            max_input_fields = 699
            max_output_fields = 699
            mix_snapshot_average_fields=.false.
/

 &flux_exchange_nml
            debug_stocks = .FALSE.
            divert_stocks_report = .TRUE.            
            do_area_weighted_flux = .FALSE.
            partition_fprec_from_lprec=.TRUE. !< NOTE: an OVERRIDE of default OM4_025 settings
/

 &fms_io_nml
            fms_netcdf_restart=.true.
            threading_read='multi'
            max_files_r = 200
            max_files_w = 200
            checksum_required = .false.
/

 &fms_nml
            clock_grain='ROUTINE'
            clock_flags='NONE'
            domains_stack_size = 5000000
            stack_size =0
/

 &ice_albedo_nml
            t_range = 10.
/

 &ice_model_nml
/

 &icebergs_nml
    verbose=.false.,
    verbose_hrs=24,
    traj_sample_hrs=24,
    debug=.false.,
    really_debug=.false.,
    use_slow_find=.true.,
    add_weight_to_ocean=.true.,
    passive_mode=.false.,
    generate_test_icebergs=.false.,
    speed_limit=0.,
    use_roundoff_fix=.true.,
    make_calving_reproduce=.true.,
 /

 &monin_obukhov_nml
            neutral = .true.
/

 &ocean_albedo_nml
            ocean_albedo_option = 2
/

 &ocean_rough_nml
            rough_scheme = 'beljaars'
/

 &sat_vapor_pres_nml
            construct_table_wrt_liq = .true.
            construct_table_wrt_liq_and_ice = .true.
/

 &surface_flux_nml
            ncar_ocean_flux = .true.
!            coare4_ocean_flux = .true.  !< NOTE: not present in default OM4_025 settings
	    raoult_sat_vap = .true.
            fixed_z_atm_tq = 2.0        !< NOTE: not present in default OM4_025 settings
            fixed_z_atm_uv = 10.0       !< NOTE: not present in default OM4_025 settings
/

 &topography_nml
            topog_file = 'INPUT/navy_topography.data.nc'
/

 &xgrid_nml
            make_exchange_reproduce = .false.
            interp_method = 'second_order'
/

EOF
