#!/bin/bash
set -e

# echo "This is the value specified for the input 'example_step_input': ${example_step_input}"

#
# --- Export Environment Variables for other Steps:
# You can export Environment Variables for other Steps with
#  envman, which is automatically installed by `bitrise setup`.
# A very simple example:
# nvman add --key EXAMPLE_STEP_OUTPUT --value 'the value you want to share'
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

# This is step.sh file for Android apps

download_file() {
	file_location=$1
	uri=$(echo $file_location | awk -F "?" '{print $1}')
	downloaded_file=$(basename $uri)
	curl -L $file_location --output $downloaded_file && echo $downloaded_file
}

export APPDOME_CLIENT_HEADER="Bitrise/1.0.0"

if [[ -z $APPDOME_API_KEY ]]; then
	echo 'APPDOME_API_KEY must be provided as a Secret. Exiting.'
	exit 1
fi

if [[ $app_location == *"http"* ]];
then
	app_file=../$(download_file $app_location)
else
	app_file=$app_location
fi
# ls -al
certificate_output=$BITRISE_DEPLOY_DIR/certificate.pdf
secured_app_output=$BITRISE_DEPLOY_DIR/Appdome_$(basename $app_file)


tm=""
if [[ -n $team_id ]]; then
	tm="--team_id ${team_id}"
fi

git clone https://github.com/Appdome/appdome-api-bash.git > /dev/null
cd appdome-api-bash


echo "Android platform detected"


cf=""
if [[ -n $SIGN_FINGERPRINT ]]; then
	cf="--signing_fingerprint ${SIGN_FINGERPRINT}"
fi

gp=""
if [[ $gp_signing == "true" ]]; then
	gp="--google_play_signing"
	if [[ -z $GOOGLE_SIGN_FINGERPRINT ]]; then
		if [[ -z $SIGN_FINGERPRINT ]]; then
			echo "GOOGLE_SIGN_FINGERPRINT must be provided as a Secret for Google Play signing. Exiting."
			exit 1
		else
			echo "GOOGLE_SIGN_FINGERPRINT was not provided, will be using SIGN_FINGERPRINT instead."
			GOOGLE_SIGN_FINGERPRINT=$SIGN_FINGERPRINT
		fi
	fi
	cf="--signing_fingerprint ${GOOGLE_SIGN_FINGERPRINT}"
fi

bl=""
if [[ $build_logs == "true" ]]; then
	bl="-bl"
fi

case $sign_method in
"Private-Signing")		echo "Private Signing"
						./appdome_api.sh --api_key $APPDOME_API_KEY \
							--app $app_file \
							--fusion_set_id $fusion_set_id \
							$tm \
							--private_signing \
							$gp \
							$cf \
							$bl \
							--output $secured_app_output \
							--certificate_output $certificate_output 
						;;
"Auto-Dev-Signing")		echo "Auto Dev Signing"
						./appdome_api.sh --api_key $APPDOME_API_KEY \
							--app $app_file \
							--fusion_set_id $fusion_set_id \
							$tm \
							--auto_dev_private_signing \
							$gp \
							$cf \
							$bl \
							--output $secured_app_output \
							--certificate_output $certificate_output 
						;;
"On-Appdome")			echo "On Appdome Signing"
						keystore_file=$(download_file $BITRISEIO_ANDROID_KEYSTORE_URL)
						keystore_pass=$BITRISEIO_ANDROID_KEYSTORE_PASSWORD
						keystore_alias=$BITRISEIO_ANDROID_KEYSTORE_ALIAS
						key_pass=$BITRISEIO_ANDROID_KEYSTORE_PRIVATE_KEY_PASSWORD
						./appdome_api.sh --api_key $APPDOME_API_KEY \
							--app $app_file \
							--fusion_set_id $fusion_set_id \
							$tm \
							--sign_on_appdome \
							--keystore $keystore_file \
							--keystore_pass $keystore_pass \
							--keystore_alias $keystore_alias \
							$gp \
							$cf \
							$bl \
							--key_pass $key_pass \
							--output $secured_app_output \
							--certificate_output $certificate_output 
						;;
esac

echo "$secured_app_output aa"

# rm -rf appdome-api-bash
if [[ $secured_app_output == *.sh ]]; then
	envman add --key APPDOME_PRIVATE_SIGN_SCRIPT_PATH --value $secured_app_output
# 	echo $secured_app_output | envman add --key APPDOME_PRIVATE_SIGN_SCRIPT_PATH
elif [[ $secured_app_output == *.apk ]]; then
	envman add --key APPDOME_SECURED_APK_PATH --value $secured_app_output
# 	echo $secured_app_output | envman add --key APPDOME_SECURED_APK_PATH
else
	envman add --key APPDOME_SECURED_AAB_PATH --value $secured_app_output
# 	echo $secured_app_output | envman add --key APPDOME_SECURED_AAB_PATH
fi
envman add --key APPDOME_CERTIFICATE_PATH --value $certificate_output
# echo $certificate_output | envman add --key APPDOME_CERTIFICATE_PATH
