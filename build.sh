#!/usr/bin/env bash
WORK_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
BUILD_DIR=${WORK_DIR}/build
mkdir -p ${BUILD_DIR}


function usage () {
    echo -en "Usage: ${0} [OPTIONS]\n\n"
    echo -en "\tUMSL App helper script to build docker container & tag.\n\n"
    echo -en "Options:\n"
    echo -en "\t-n         \tNo Operations(DryRun) mode.\n"
    echo -en "\t-h         \tPrint this help page."
}

function build_docker_container () {
    if [[ ${DRYRUN} == "false" ]]; then
        docker build -t ${CONTAINER_TAG} .
        if [[ $? != 0 ]]; then exit 3; fi
        docker tag ${CONTAINER_TAG} emirates/umsl-app:latest
        docker tag emirates/umsl-app:latest 713682226939.dkr.ecr.ap-south-1.amazonaws.com/emirates/umsl-app:latest
        docker tag ${CONTAINER_TAG} 713682226939.dkr.ecr.ap-south-1.amazonaws.com/${CONTAINER_TAG}
    fi
}


## Main ##
DRYRUN="false"
PUSH_TO_AWS="false"
ADDDRYRUN=""

# get build version
BASE_VERSION="0.0.1"
BUILD_VERSION="${BASE_VERSION}-$(git rev-parse --short HEAD)"
CONTAINER_TAG="emirates/umsl-app:${BUILD_VERSION}"

# Read the options
while getopts pnh FLAG; do
    case ${FLAG} in
        h)  usage
            exit 0 ;;
        n)  DRYRUN="true"
            ADDDRYRUN="(DRYRUN) " ;;
        p)  PUSH_TO_AWS="true" ;;
        *) # unrecognized option - show help
            if [[ "$OPTERR" != 1 ]] || [[ "${OPTSPEC:0:1}" = ":" ]]; then
                echo -en "ERROR: Option - ${FLAG} not allowed.\n\n"
                usage
            fi
            exit 3 ;;
  esac
done

echo -en "${ADDDRYRUN}INFO: Building & Tagging local application container...\n"
if [[ ${DRYRUN} == "false" ]]; then
   ./mvnw -Pprod clean verify && build_docker_container
fi

if [[ ${PUSH_TO_AWS} == "true" ]]; then
    echo -en "${ADDDRYRUN}INFO: Pushing application image to AWS docker registry...\n"
    if [[ ${DRYRUN} == "false" ]]; then
        $(aws ecr get-login --no-include-email --region ap-south-1)
        docker push 713682226939.dkr.ecr.ap-south-1.amazonaws.com/emirates/umsl-app:latest
        docker push 713682226939.dkr.ecr.ap-south-1.amazonaws.com/${CONTAINER_TAG}
    fi
    echo -en "${ADDDRYRUN}INFO: Container tags pushed : latest, ${BUILD_VERSION}\n"
fi

echo -en "${ADDDRYRUN}INFO: Build completed.\n"
echo -en "\n================== Build Results ==================\n"
echo -en "${ADDDRYRUN}Container name: umsl-app\n"
echo -en "${ADDDRYRUN}Container tags: ${BUILD_VERSION}, latest\n"
echo -en "${ADDDRYRUN}Pushed to AWS Docker Registry : ${PUSH_TO_AWS}\n"
echo -en "===================================================\n\n"

cd ${WORK_DIR}; rm -rf ${BUILD_DIR}
echo -en "INFO: Cleaned up the build directory.\n"
