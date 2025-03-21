#!/bin/bash
set -e

# echo "This is the value specified for the input 'example_step_input': ${example_step_input}"

#
# --- Export Environment Variables for other Steps:
# You can export Environment Variables for other Steps with
#  envman, which is automatically installed by `bitrise setup`.
# A very simple example:
# envman add --key EXAMPLE_STEP_OUTPUT --value 'the value you want to share'
# Envman can handle piped inputs, which is useful if the text you want to
# share is complex and you don't want to deal with proper bash escaping:
#  cat file_with_complex_input | envman add --KEY EXAMPLE_STEP_OUTPUT
# You can find more usage examples on envman's GitHub page
#  at: https://github.com/bitrise-io/envman

#
# --- Exit codes:
# The exit code of your Step is very important. If you return
#  with a 0 exit code `bitrise` will register your Step as "successful".
# Any non zero exit code will be registered as "failed" by `bitrise`.

# This is step_init.sh file for Android apps

# version: 3.4

# parameters validation:
if [[ -z $APPDOME_API_KEY ]]; then
	echo 'No APPDOME_API_KEY was provided. Exiting.'
	exit 1
fi

if [[ -z $app_location ]]; then
    echo "No App Location was provided. Exiting."
    exit 1
fi

if [[ -z $output_filename ]];then
    output_filename="_@_"
fi

if [[ -z $fusion_set_id ]];then
    echo "No Fusion Set ID was provided. Exiting."
    exit 1
fi

if [[ -z $team_id ]];then
    team_id="_@_"
fi

if [[ -z $google_fingerprint ]];then
    google_fingerprint="_@_"
fi

if [[ -z $fingerprint ]];then
    fingerprint="_@_"
fi

if [[ -z $workflow_output_logs ]];then
    workflow_output_logs="_@_"
fi

if [[ -z $crashlytics_app_id ]];then
    crashlytics_app_id="_@_"
fi

if [[ -z $datadog_api_key ]];then
    datadog_api_key="_@_"
fi

branch="RealStep"
if [[ -n $APPDOME_BRANCH_ANDROID ]]; then
    branch=$APPDOME_BRANCH_ANDROID
fi

echo "Running Branch: $branch"
# step execusion
git clone --branch $branch https://github.com/Appdome/bitrise-step-appdome-build-2secure-android.git  > /dev/null
cd bitrise-step-appdome-build-2secure-android
bash ./step.sh "$app_location" "$fusion_set_id" "$team_id" "$sign_method" "$gp_signing" "$google_fingerprint" "$fingerprint" "$build_logs" "$build_to_test" "$secondary_output" "$output_filename" "$workflow_output_logs" "$download_deobfuscation" "$crashlytics_app_id" "$datadog_api_key"
exit $(echo $?)