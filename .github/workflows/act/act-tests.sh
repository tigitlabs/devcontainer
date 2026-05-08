#!/bin/bash
# Test script to verify workflows locally with ACT

echo "🧪 Running act tests $1 🧪"

DEBUG_WORKFLOW_FILE=".github/workflows/debug.yml"
MARKDOWN_WORKFLOW_FILE=".github/workflows/docs.yml"
PUBLISH_WORKFLOW_FILE=".github/workflows/publish.yml"
ACT_WORKFLOW_FILE=".github/workflows/act.yml"
MAKEFILE_WORKFLOW_FILE=".github/workflows/makefile-ci.yml"
SMOKETEST_BASE_UBUNTU_WORKFLOW_FILE=".github/workflows/smoke-base-ubuntu.yaml"

# Event files
PUSH_TAG_EVENT_FILE=".github/workflows/act/event-push-tag.json"
PUSH_COMMIT_EVENT_FILE=".github/workflows/act/event-push-commit.json"
PR_OPEN_EVENT_FILE=".github/workflows/act/event-pr-opened.json"

# Function to run act --dryrun and check for errors
# $1: The workflow file to run
function act_dryrun {
    local workflow="$1"
    local result
    echo "🧪🧪🧪 Testing act --dryrun ${workflow} 🧪🧪🧪"
    echo "🏃: act --dryrun --workflows ${workflow} --secret GITHUB_TOKEN=\${GITHUB_TOKEN} --actor \${GITHUB_USER}"
    result=$(act --dryrun --workflows "${workflow}" \
        --secret GITHUB_TOKEN="${GITHUB_TOKEN}" \
        --actor "${GITHUB_USER}" 2>&1)

    if [[ "${result}" == *"Job succeeded"* ]]; then
        echo "✅ Test passed"
    elif [[ -z "${result}" ]]; then
        echo "⚠️ Nothing returned from act"
    else
        echo "❌ Test failed"
        echo "${result}"
        exit 1
    fi
}

#   $1: The event name. This is the name of the GitHub event that triggers the workflow.
#   $2: The workflow file. This is the path to the file that defines the workflow.
#   $3: The event file. This is the path to the file that contains the payload for the event.
function act_dryrun_event {
    local event="$1"
    local workflow="$2"
    local event_file="$3"
    local result
    echo "🧪🧪🧪 Testing act Event: ${event} Workflow: ${workflow} with Event file: ${event_file} 🧪🧪🧪"
    echo "🏃: act ${event} --workflows ${workflow} --secret GITHUB_TOKEN=\${GITHUB_TOKEN} --actor \${GITHUB_USER} --dryrun --eventpath ${event_file}"
    result=$(act "${event}" \
        --workflows "${workflow}" \
        --secret GITHUB_TOKEN="${GITHUB_TOKEN}" \
        --actor "${GITHUB_USER}" \
        --dryrun \
        --eventpath "${event_file}" 2>&1)

    if [[ "${result}" == *"Job succeeded"* ]]; then
        echo "✅ Test passed"
    else
        echo "❌ Test failed"
        echo "${result}"
        exit 1
    fi
}

# Function to run act_dryrun for all workflows
function act_dryrun_all {
    echo "🧪🧪🧪 Testing all workflows with dryrun 🧪🧪🧪"
    act_dryrun "${MAKEFILE_WORKFLOW_FILE}"
    act_dryrun "${MARKDOWN_WORKFLOW_FILE}"
    act_dryrun "${SMOKETEST_BASE_UBUNTU_WORKFLOW_FILE}"
    act_dryrun "${ACT_WORKFLOW_FILE}"
    # TODO this fails
    act_dryrun "${PUBLISH_WORKFLOW_FILE}"
}

function check_env() {
    echo "🧪🧪🧪 Check GITHUB variables 🧪🧪🧪"
    set -e
    if [[ -z "${GITHUB_TOKEN}" || -z "${GITHUB_USER}" ]]; then
        echo "GITHUB_TOKEN or GITHUB_USER not set"
        exit 1
    else
        echo "✅ GITHUB_TOKEN and GITHUB_USER set"
    fi
}

function act_github_event() {
    echo "🧪🧪🧪 Testing act with event files 🧪🧪🧪"
    echo "🧪🧪🧪 push commit event 🧪🧪🧪"
    act push --workflows "${DEBUG_WORKFLOW_FILE}" --eventpath "${PUSH_COMMIT_EVENT_FILE}"
    echo "🧪🧪🧪 push tag event 🧪🧪🧪"
    act push --workflows "${DEBUG_WORKFLOW_FILE}" --eventpath "${PUSH_TAG_EVENT_FILE}"
    echo "🧪🧪🧪 PR open event 🧪🧪🧪"
    act pull_request --workflows "${DEBUG_WORKFLOW_FILE}" --eventpath "${PR_OPEN_EVENT_FILE}"
}

function act_test_publish_workflow() {
    echo "🧪🧪🧪 Test publish workflow push branch event 🧪🧪🧪"
    act push --workflows "${PUBLISH_WORKFLOW_FILE}" --eventpath "${PUSH_COMMIT_EVENT_FILE}" --dryrun
    echo "🧪🧪🧪 Test publish workflow push tag event 🧪🧪🧪"
    act push --workflows "${PUBLISH_WORKFLOW_FILE}" --eventpath "${PUSH_TAG_EVENT_FILE}" --dryrun
    echo "🧪🧪🧪 Test publish workflow pull request event 🧪🧪🧪"
    act pull_request --workflows "${PUBLISH_WORKFLOW_FILE}" --eventpath "${PR_OPEN_EVENT_FILE}" --dryrun
}

if [[ -z "$1" ]]; then
    echo "Running all tests"
    check_env
    act_github_event
    act_dryrun_all
    act_test_publish_workflow
elif [[ "$1" == "dryrun" ]]; then
    echo "Running dryrun tests"
    check_env
    act_dryrun_all
    act_test_publish_workflow
elif [[ "$1" == "event" ]]; then
    echo "Running event tests"
    check_env
    act_github_event
elif [[ "$1" == "publish" ]]; then
    echo "Running publish workflow tests"
    check_env
    act_test_publish_workflow
else
    echo "🚫 Unknown argument $1"
    exit 1
fi
