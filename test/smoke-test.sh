#!/bin/bash
# Initialize variables
verbose=0
pull=false

# Parse the flags
while getopts "o:v:p" opt; do
  case ${opt} in
    v )
      verbose=1
      ;;
    p )
      pull=true
      ;;
    \? )
      echo "Invalid option: $OPTARG" 1>&2
      ;;
    : )
      echo "Invalid option: $OPTARG requires an argument" 1>&2
      ;;
  esac
done
shift $((OPTIND -1))

echo "verbose: $verbose"
echo "push: $push"

script_dir="$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1
build_script="${script_dir}/pre_build.sh"
test_script="${script_dir}/test_build.sh"
# Get current branch name
branch=$(git rev-parse --abbrev-ref HEAD)

if [ ! -f "${build_script}" ]; then
    echo "🚫 Could not find build script at ${build_script}"
    exit 1
fi

function build {
    echo "🐋 Building ${1}"
    TAG="${branch}"
    PULL="${pull}"
    ./${build_script} ${1} ${TAG}
}

function test {
    echo "🧪 Testing ${1}"
    TAG="${branch}"
    ./${test_script} ${1} ${TAG}
}

build "base-ubuntu" && test "base-ubuntu"
