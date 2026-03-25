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

# version: 3.6

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

if [[ -z $multiple_trusted_signing_certs_path ]];then
    multiple_trusted_signing_certs_path="_@_"
fi

# Optional: pick a Bitrise Code Signing keystore by the *URL* env var name; password / alias /
# private key password names are derived from that name.
#   BITRISEIO_ANDROID_KEYSTORE_4_URL  -> ..._4_PASSWORD, ..._4_ALIAS, ..._4_PRIVATE_KEY_PASSWORD
#   BITRISEIO_ANDROID_KEYSTORE_URL_4  -> ..._PASSWORD_4, ..._ALIAS_4, ..._PRIVATE_KEY_PASSWORD_4
# Remaps into BITRISEIO_ANDROID_KEYSTORE_* so RealStep step.sh is unchanged.
if [[ -n "${android_keystore_url_env:-}" ]]; then
    if [[ ! $android_keystore_url_env =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
        echo "Invalid android_keystore_url_env name: '${android_keystore_url_env}'"
        exit 1
    fi
    if [[ $android_keystore_url_env =~ ^BITRISEIO_ANDROID_KEYSTORE_URL_(.+)$ ]]; then
        _ks_suf="${BASH_REMATCH[1]}"
        _ks_pass_ref="BITRISEIO_ANDROID_KEYSTORE_PASSWORD_${_ks_suf}"
        _ks_alias_ref="BITRISEIO_ANDROID_KEYSTORE_ALIAS_${_ks_suf}"
        _ks_keypass_ref="BITRISEIO_ANDROID_KEYSTORE_PRIVATE_KEY_PASSWORD_${_ks_suf}"
    elif [[ $android_keystore_url_env =~ ^(.+)_URL$ ]]; then
        _ks_base="${BASH_REMATCH[1]}"
        _ks_pass_ref="${_ks_base}_PASSWORD"
        _ks_alias_ref="${_ks_base}_ALIAS"
        _ks_keypass_ref="${_ks_base}_PRIVATE_KEY_PASSWORD"
    else
        echo "android_keystore_url_env must end with _URL, e.g. BITRISEIO_ANDROID_KEYSTORE_4_URL or BITRISEIO_ANDROID_KEYSTORE_URL_4. Got: '${android_keystore_url_env}'"
        exit 1
    fi
    for _ks_slot in _ks_pass_ref _ks_alias_ref _ks_keypass_ref; do
        eval "_n=\$$_ks_slot"
        if [[ ! $_n =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
            echo "Derived invalid env var name: '${_n}'"
            exit 1
        fi
    done
    echo "Derived keystore env vars from ${android_keystore_url_env}: ${_ks_pass_ref}, ${_ks_alias_ref}, ${_ks_keypass_ref}"
    eval "_ks_url_val=\$$android_keystore_url_env"
    eval "_ks_pass_val=\$$_ks_pass_ref"
    eval "_ks_alias_val=\$$_ks_alias_ref"
    eval "_ks_keypass_val=\$$_ks_keypass_ref"
    if [[ -z $_ks_url_val ]]; then
        echo "Keystore URL is empty: env var '${android_keystore_url_env}' is unset or empty."
        exit 1
    fi
    export BITRISEIO_ANDROID_KEYSTORE_URL="$_ks_url_val"
    export BITRISEIO_ANDROID_KEYSTORE_PASSWORD="$_ks_pass_val"
    export BITRISEIO_ANDROID_KEYSTORE_ALIAS="$_ks_alias_val"
    export BITRISEIO_ANDROID_KEYSTORE_PRIVATE_KEY_PASSWORD="$_ks_keypass_val"
    echo "Using keystore from Code Signing env vars: ${android_keystore_url_env} (remapped to BITRISEIO_ANDROID_KEYSTORE_URL)."
fi

branch="RealStep"
if [[ -n $APPDOME_BRANCH_ANDROID ]]; then
    branch=$APPDOME_BRANCH_ANDROID
fi

echo "Running Branch: $branch"
# step execusion
git clone --branch $branch https://github.com/Appdome/bitrise-step-appdome-build-2secure-android.git  > /dev/null
cd bitrise-step-appdome-build-2secure-android
bash ./step.sh "$app_location" "$fusion_set_id" "$team_id" "$sign_method" "$gp_signing" "$google_fingerprint" "$fingerprint" "$build_logs" "$build_to_test" "$secondary_output" "$output_filename" "$workflow_output_logs" "$download_deobfuscation" "$crashlytics_app_id" "$datadog_api_key" "$multiple_trusted_signing_certs_path"
exit $(echo $?)