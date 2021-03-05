#!/bin/bash

# Check arguments
if [[ $# -eq 0 ]] ; then
    echo 'usage: run_sr.sh <test_folder_name> [sr_version]'
    echo
    echo 'NOTE: Requires env variables from ../sr_cluster.env'
    exit 1
fi

# Source environment and get arguments
source $SR_CLUSTER_ROOT_DIR/sr_cluster.env
scripts_path=$SR_CLUSTER_ROOT_DIR/scripts
test_folder_name=$1

if [ -z "${SR_VERSION}" ]; then
    echo 'ERROR: please set SR_VERSION (looks like sr_cluster.env is not being sourced)'
    exit 1
fi

# Set SR_VERSION or keep default
if [ ! -z "$2" ] && [ "${SR_VERSION}" != $2 ]; then
	export SR_VERSION=$2
fi

# Create test and log directories
mkdir -p $SR_TMP_DIR
jobid=${SLURM_JOB_ID:-$(date +%s)}
if [ -n "$SLURM_JOB_NAME" ]
then
  jobname="slurm"
else
  jobname="local"
fi
sr_dir="$SR_TMP_DIR/${jobname}-${jobid}"
if [ -d $sr_dir ]; then
    echo "WARNING: Found old content at ${sr_dir} - removing"
    rm -fR $sr_dir
fi

# Copy test spec from cloud
rclone copy -v ${SR_CLUSTER_TEST_SPEC_PATH}/${test_folder_name} ${sr_dir}

if [ ! -d ${sr_dir} ]
then
    echo "Error copying test folder $test_folder_name from cloud storage"
    echo "Available test specs are: "
    rclone lsf ${SR_CLUSTER_TEST_SPEC_PATH} | sed 's/\///'
    exit 1
fi

# Note: removing handling of logs and letting SR dump logs to 'output' folder
test_logs_dir=$sr_dir/output
#export TEST_LOGS_DIR=$test_logs_dir
mkdir -p $test_logs_dir

# Run SR
echo "Running on: " `hostname`
#command="env DISPLAY=:0.0 $scripts_path/launch_sr.sh run ${sr_dir} |& tee $test_logs_dir/sr_output.txt"
command="env DISPLAY=:0.0 $scripts_path/launch_sr.sh run ${sr_dir}"
echo "Running Scenario Runner: ${command}"

eval $command

# Copy output back to cloud storage
cloud_folder=${SR_CLUSTER_TEST_OUTPUT_PATH}/${jobname}-${jobid}-${test_folder_name}-sr_${sr_version}
echo "Copying logs to cloud folder $cloud_folder"

rclone mkdir $cloud_folder
rclone copy $sr_dir $cloud_folder
