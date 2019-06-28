#!/bin/bash
set -e
cat << \#\#

#================================================================================
#================================================================================
# NCEP Hybrid-GODAS  -  fcst.run.sh
#   MOM6 ocean forecast ensemble member model run
#================================================================================
##
#
# Prerequisites:
#
# Results:
#  * MOM6 forecasts will run in the $FCST_DIR location.
#  * The restart files will be moved to $RST_DIR
#  * other output files will NOT be moved out of the working directory by this
#    script, other jobsteps handle that task
#
# Required environment variables:
 envar=()
 envar+=("FCST_DIR")         # The directory that the forecast will be run in
 envar+=("FORC_DIR")         # directory for the generated surface forcings
 envar+=("RST_DIR_IN")
 envar+=("RST_DIR_OUT")
 envar+=("PPN")              # Number of cores per node (procs per node)
 envar+=("NODES")            # Number of nodes to use for MPI enabled forecast
 envar+=("FCST_RST_TIME")    # datetime for forecast restart outptut (YYYYMMDDHH)
 envar+=("FCST_START_TIME")  # datetime for start of forecast (YYYYMMDDHH)
 envar+=("FCST_LEN")         # length of forecast (hours)
 envar+=("FCST_RESTART")     # 1 if yes, 0 if no
 envar+=("FCST_DIAG_DA")     # 1 if the diagnostic output required for DA is to be saved
 envar+=("FCST_DIAG_OTHER")  # 1 if other diag output (not needed for DA) is to be saved
#================================================================================
#================================================================================


# make sure required env vars exist
for v in ${envar[@]}; do
    if [[ -z "${!v}" ]]; then
	echo "ERROR: env var $v is not set."; exit 1
    fi
    echo " $v = ${!v}"
done
echo ""
set -u


# calculate number of cores needed
NPROC=$(($PPN * $NODES))
echo "Running with $NPROC cores"


# setup the foreacst directory
#------------------------------------------------------------
echo "Setting up forecast working directory in:"
echo " $FCST_DIR"
if [[ -e "$FCST_DIR" ]]; then
    echo "WARNING: $FCST_DIR already exists, removing."
    rm -rf $FCST_DIR
fi
mkdir -p $FCST_DIR
cd $FCST_DIR

mkdir -p OUTPUT
ln -s $FORC_DIR FORC
ln -s $ROOT_GODAS_DIR/build/MOM6 .

# namelist files
cp $ROOT_EXP_DIR/config/mom/* .
source diag_table.sh > diag_table
source input.nml.sh > input.nml

# static input files
# TODO, these should be linked into exp's config dir at exp init
# time?
mkdir -p INPUT
ln -s $ROOT_GODAS_DIR/run/config.exp_default/mom_input/* INPUT/

# link restart files
#dtz() { echo "${1:0:8}Z${1:8:10}"; }
#t=$(dtz $FCST_START_TIME)
#rst_dir_in=$(date "+$RST_DIR" -d "$t")
#ln -s $rst_dir_in ./RESTART_IN
ln -s $RST_DIR_IN ./RESTART_IN

# output directory for restart files
mkdir -p $RST_DIR_OUT
ln -s $RST_DIR_OUT RESTART


# run the forecast
#------------------------------------------------------------
echo "running MOM..."
aprun -n $NPROC ./MOM6


# the intermediate restart files are being a little weird currently.
# Do this the messy way until I have time to look into the MOM/SIS code.
# Rename the intermediate restart files after the model finishes...
cd RESTART
for f in ????????.????00.*.res*; do 
    mv $f ${f:16}
done
