#!/bin/bash
image_location=$SR_IMAGE_LOCATION
version=$SR_VERSION

# Check image variables
if [ -z "$image_location" ] || [ -z "$version" ] ; then
	echo 'ERROR: please set SR_IMAGE_VERSION and SR_IMAGE_LOCATION environment variables'
	return 1
fi

# Check if the last arg looks like a flag. e.g. --help
last_arg="${@: -1}"

# Only "version" and sr --help has 1 input command
if [[ $# == 1 ]]; then
    abs_path_deployment_dir=""
    parent_dir=$(pwd)
    sr_command=$last_arg
# For sr create --help
elif [[ ${last_arg:0:1} == '-' ]]; then
    abs_path_deployment_dir=""
    parent_dir=$(pwd)
    sr_command="${@:1:$#-1} --help"
else
    # Compute parent of the last arg, which is the deployment dir
    abs_path_deployment_dir=$(realpath "$last_arg")
    parent_dir=$(dirname "$abs_path_deployment_dir")
    sr_command=${@:1:$#-1}
fi

# Compute the group id number of docker
docker_gid=$(cut -d: -f3 < <(getent group docker 2>/dev/null))

docker run \
    -e DISPLAY --rm -it --net host \
    --cap-add=NET_ADMIN --cap-add=SYS_MODULE \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /etc/shadow:/etc/shadow:ro \
    -v /etc/group:/etc/group:ro \
    -v /etc/passwd:/etc/passwd:ro \
    -v /etc/sudoers:/etc/sudoers:ro \
    -v /lib/modules:/lib/modules:ro \
    -v $HOME/.sr/credentials.yaml:$HOME/.sr/credentials.yaml \
    -v "$parent_dir":"$parent_dir" \
    -u $(id -u):$(id -g) --group-add sudo \
    $(if [ ! -z "$docker_gid" ];then echo "--group-add $docker_gid";fi) \
    --entrypoint /sr $image_location:$version $sr_command $abs_path_deployment_dir

