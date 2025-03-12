#!/bin/bash
set -e
# file version: RS-A-3.8
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

appdome_pipeline_values () {
	sign_method=$APPDOME_PIPELINE_SIGNING_METHOD
	 
	if [[ -n $APPDOME_PIPELINE_BUILD_WITH_LOGS ]]; then
		build_logs=$APPDOME_PIPELINE_BUILD_WITH_LOGS
	fi

	if [[ -n $APPDOME_PIPELINE_BUILD_TO_TEST ]]; then
		build_to_test=$APPDOME_PIPELINE_BUILD_TO_TEST
	fi

	if [[ -n $APPDOME_PIPELINE_GOOGLE_PLAY_SIGNING ]]; then
		gp_signing=$APPDOME_PIPELINE_GOOGLE_PLAY_SIGNING
	fi
}

debug () {
	echo "Running in Debug mode... Please wait for completion."
	echo "DEBUG DATA:" > $BITRISE_DEPLOY_DIR/debug.txt
	echo "-----------" > $BITRISE_DEPLOY_DIR/debug.txt
	echo "App: $app_file" >> $BITRISE_DEPLOY_DIR/debug.txt
	echo "API key: $APPDOME_API_KEY" >> $BITRISE_DEPLOY_DIR/debug.txt
	echo "Sign method: $sign_method" >> $BITRISE_DEPLOY_DIR/debug.txt
	echo "Sign command: $sign_command" >> $BITRISE_DEPLOY_DIR/debug.txt
	echo "Keystore file: $keystore_file" >> $BITRISE_DEPLOY_DIR/debug.txt
	echo "Keystore alias: $keystore_alias" >> $BITRISE_DEPLOY_DIR/debug.txt
	echo "Keystore pass: $keystore_pass" >> $BITRISE_DEPLOY_DIR/debug.txt
	echo "Fusion set ID: $fusion_set_id" >> $BITRISE_DEPLOY_DIR/debug.txt
	echo "TM: $tm" >> $BITRISE_DEPLOY_DIR/debug.txt
	echo "FP: $gp" >> $BITRISE_DEPLOY_DIR/debug.txt
	echo "SF: $sf" >> $BITRISE_DEPLOY_DIR/debug.txt 
	echo "BL: $bl" >> $BITRISE_DEPLOY_DIR/debug.txt 
	echo "BTV: $btv" >> $BITRISE_DEPLOY_DIR/debug.txt 
	echo "SO: $so" >> $BITRISE_DEPLOY_DIR/debug.txt 
	echo "DSO: $dso" >> $BITRISE_DEPLOY_DIR/debug.txt 
	echo "DD: $dd" >> $BITRISE_DEPLOY_DIR/debug.txt 
	echo "AID: $aid" >> $BITRISE_DEPLOY_DIR/debug.txt 
	echo "WOL: $wol" >> $BITRISE_DEPLOY_DIR/debug.txt 
	echo "Secured output: $secured_app_output" >> $BITRISE_DEPLOY_DIR/debug.txt 
	echo "Certificate output: $certificate_output" >> $BITRISE_DEPLOY_DIR/debug.txt 
	echo >> $BITRISE_DEPLOY_DIR/debug.txt
	pwd >> $BITRISE_DEPLOY_DIR/debug.txt
	ls -al >> $BITRISE_DEPLOY_DIR/debug.txt
	ls -al .. >> $BITRISE_DEPLOY_DIR/debug.txt
	echo >> $BITRISE_DEPLOY_DIR/debug.txt
	echo ./appdome_api $cmd >> $BITRISE_DEPLOY_DIR/debug.txt
	# echo --api_key $APPDOME_API_KEY \
	# 	--app $app_file \
	# 	--fusion_set_id $fusion_set_id \
	# 	$tm \
	# 	$sign_command \
	# 	--keystore $keystore_file \
	# 	--keystore_pass $keystore_pass \
	# 	--keystore_alias $keystore_alias \
	# 	$gp \
	# 	$sf \
	# 	$bl \
	# 	$btv \
	# 	$so \
	# 	$dso \
	# 	$dd \
	# 	$aid \
	# 	$wol \
	# 	--output $secured_app_output \
	# 	--certificate_output $certificate_output >> $BITRISE_DEPLOY_DIR/debug.txt
	echo "Done. See debug.txt in Artifacts section for results."
	cd $PWD/..
	pwd=$PWD
	cd $PWD/..
	rm -rf $pwd
	exit 0
}

print_all_params() {
	echo "Appdome Build-2Secure parameters:"
	echo "=================================="
	echo "App location: $app_location"
	echo "Output file: $secured_app_output"
	echo "Fusion Set ID: $fusion_set_id"
	echo "Team ID: $team_id"
	echo "Sign Method: $sign_method"
	echo "Keystore file: $keystore_file" 
	echo "Keystore password: $ks_pass" 
	echo "Keystore alias: $keystore_alias" 
	echo "Key password: $private_key_pass" 
	echo "Google Play Singing: $gp_signing"
	echo "Google Fingerprint: $GOOGLE_SIGN_FINGERPRINT" 
	echo "Sign Fingerprint: $SIGN_FINGERPRINT"
	echo "Build with logs: $build_logs" 
	echo "Build to Test: $build_to_test" 
	echo "Secured app output: $secured_app_output"
	echo "Certificate output: $certificate_output"
	echo "Secondary output: $secured_so_app_output"
	echo "Workflow output logs file: $workflow_output_logs"
	echo "Deobfuscation mapping files location: $deob_output"
	echo "Crashlytics app id: $app_id"
	echo "Datadog API key: $datadog_api_key"
	echo "-----------------------------------------"
}

download_file() {
	file_location=$(echo "$1" | tr -cd '\000-\177')
	uri=$(echo $file_location | awk -F "?" '{print $1}')
	downloaded_file=$(basename $uri)
	curl -L $file_location --output $downloaded_file && echo $downloaded_file
}

internal_version="RS-A-3.8"
echo "Internal version: $internal_version"
export APPDOME_CLIENT_HEADER="Bitrise/3.8.0"

app_location=$1
fusion_set_id=$2
team_id=$3
sign_method=$4
gp_signing=$5
google_fingerprint=$6
fingerprint=$7
build_logs=$8
build_to_test=$9
secondary_output=${10}
output_filename=${11}
certificate_file=${12}
keystore_pass=${13}
keystore_alias=${14}
private_key_password=${15}
workflow_output_logs=${16}
download_deobfuscation=${17}
app_id=${18} 
datadog_api_key=${19}


if [[ -n $APPDOME_PIPELINE_SIGNING_METHOD ]]; then
	appdome_pipeline_values
fi

build_to_test=$(echo "$build_to_test" | tr '[:upper:]' '[:lower:]')

if [[ -z $APPDOME_API_KEY ]]; then
	echo 'APPDOME_API_KEY must be provided as a Secret. Exiting.'
	exit 1
fi

if [[ $app_location == *"http"* ]]; then
	app_file=../$(download_file $app_location)
else
	app_file=$app_location
	if [[ $app_location == *" "* ]]; then
		app_file=${app_file//" "/"_"}
		cp "$app_location" "$app_file"
	fi
fi

aid=""
if [[ $app_id != "_@_" ]]; then 
	aid="-aid $app_id"
fi

so=""
secured_so_app_output="none"
extension=${app_file##*.}

if [[ $output_filename == "_@_" || -z $output_filename ]]; then
	secured_app_output=$BITRISE_DEPLOY_DIR/Appdome_$(basename $app_file)
	secured_so_app_output="$BITRISE_DEPLOY_DIR/Appdome_Universal.apk"
else
	secured_app_output=$BITRISE_DEPLOY_DIR/$output_filename.$extension
	secured_so_app_output="$BITRISE_DEPLOY_DIR/Universal_$output_filename.apk"
fi

if [[ $extension == "aab" && $secondary_output == "true" ]]; then
	so="--second_output $secured_so_app_output"
fi

certificate_output=$BITRISE_DEPLOY_DIR/certificate.pdf


if [[ $team_id == "_@_" ]]; then
	team_id=""
	tm=""
else
	tm="--team_id ${team_id}"
fi

branch="master"
if [[ -n $APPDOME_API_BRANCH ]]; then
	branch=$APPDOME_API_BRANCH
fi

git clone --branch $branch https://github.com/Appdome/appdome-api-bash.git > /dev/null
cd appdome-api-bash

echo "Android platform detected"

if [[ $keystore_alias == "_@_" ]]; then
	keystore_alias=""
fi


sf=""
if [[ $fingerprint != "_@_" ]]; then
	sf="--signing_fingerprint ${fingerprint}"
fi

wol=""
if [[ $workflow_output_logs != "_@_" ]]; then
	workflow_output_logs=$BITRISE_DEPLOY_DIR/$workflow_output_logs
	wol="--workflow_output_logs ${workflow_output_logs}"
else
	workflow_output_logs=""
fi

gp=""
if [[ $gp_signing == "true" ]]; then
	if [[ -z $google_fingerprint || $google_fingerprint == "_@_" ]]; then
		if [[ -z $fingerprint ]]; then
			echo "Google Sign Fingerprint must be provided for Google Play signing. Exiting."
			exit 1
		else
			echo "Google Sign Fingerprint was not provided, will be using Sign Fringerprint instead."
			google_fingerprint=$fingerprint
		fi
	fi
	gp="--google_play_signing --signing_fingerprint ${google_fingerprint}"
	sf=""
fi

bl=""
if [[ $build_logs == "true" ]]; then
	bl="--build_logs"
fi

btv=""
if [[ $build_to_test != "none" ]]; then
	btv="--build_to_test_vendor $build_to_test"
fi

dso=""
deob_output=""
if [[ $download_deobfuscation == "true" ]]; then
	deob_output=$BITRISE_DEPLOY_DIR/deobfuscation_mapping_files.zip
	dso="-dso ${deob_output}"
fi

dd=""
if [[ $datadog_api_key != "_@_" ]]; then
	dd="-dd_api_key $datadog_api_key"
fi

sign_command=""

case $sign_method in
"Private-Signing")		
						echo "Private Signing"
						sign_command="--private_signing"
						print_all_params
						cmd='--api_key $APPDOME_API_KEY \
							--app "$app_file" \
							--fusion_set_id $fusion_set_id \
							$tm \
							$sign_command \
							$gp \
							$sf \
							$bl \
							$btv \
							$so \
							$dso \
							$dd \
							$aid \
							$wol \
							--output "$secured_app_output" \
							--certificate_output "$certificate_output"'

						if [[ $APPDOME_DEBUG == "1" ]]; then
							debug
						fi
						;;
"Auto-Dev-Signing")		
						echo "Auto Dev Signing"
						sign_command="--auto_dev_private_signing"
						secured_app_output_name=${secured_app_output%.*}
						secured_app_output=$secured_app_output_name.sh
						
						print_all_params
						cmd='--api_key $APPDOME_API_KEY \
							--app "$app_file" \
							--fusion_set_id $fusion_set_id \
							$tm \
							$sign_command \
							$gp \
							$sf \
							$bl \
							$btv \
							$dso \
							$dd \
							$aid \
							$wol \
							--output "$secured_app_output" \
							--certificate_output "$certificate_output"'
						
						if [[ $APPDOME_DEBUG == "1" ]]; then
							debug
						fi
						;;
"On-Appdome")			
						echo "On Appdome Signing"
						sign_command="--sign_on_appdome"
						if [[ $certificate_file == "_@_" || -z $certificate_file ]]; then
							if [[ -n $BITRISEIO_ANDROID_KEYSTORE_URL ]]; then
								certificate_file=$BITRISEIO_ANDROID_KEYSTORE_URL
								keystore_pass=$BITRISEIO_ANDROID_KEYSTORE_PASSWORD
								private_key_password=$BITRISEIO_ANDROID_KEYSTORE_PRIVATE_KEY_PASSWORD
								keystore_alias=$BITRISEIO_ANDROID_KEYSTORE_ALIAS
							elif [[ -n $BITRISEIO_ANDROID_KEYSTORE_1_URL ]]; then
									certificate_file=$BITRISEIO_ANDROID_KEYSTORE_1_URL
									keystore_pass=$BITRISEIO_ANDROID_KEYSTORE_1_PASSWORD
									private_key_password=$BITRISEIO_ANDROID_KEYSTORE_1_PRIVATE_KEY_PASSWORD
									keystore_alias=$BITRISEIO_ANDROID_KEYSTORE_1_ALIAS
							else
								echo "Could not find keystore file. Please recheck Android keystore file environment variable. Exiting."
								exit 1
							fi
						fi

						keystore_file=$(download_file $certificate_file)
						ks_pass=""
						if [[ -n $keystore_pass && $keystore_pass != "_@_" ]]; then
							ks_pass="[REDACTED]"
						fi

						private_key_pass=""
						if [[ -n $private_key_password && $private_key_password != "_@_" ]]; then
							private_key_pass="[REDACTED]"
						fi

						if [[ $APPDOME_DEBUG == "1" ]]; then
							debug
						fi

						print_all_params

						if [[ ! -s $keystore_file ]]; then
							echo "Failed obtaining keystore file. Please recheck Android keystore file environment variable. Exiting."
							exit 1
						fi
						if [[ $keystore_pass == "_@_" ||  -z $keystore_pass ]]; then
							echo "Could not find keystore password. Please recheck Android keystore file environment variable. Exiting."
							exit 1
						fi
						if [[ $keystore_alias == "_@_" || -z $keystore_alias ]]; then
							echo "Could not find keystore alias. Please recheck Android keystore file environment variable. Exiting."
							exit 1
						fi
						if [[ $private_key_password == "_@_" || -z $private_key_password ]]; then
							echo "Could not find keystore private key password. Please recheck Android keystore file environment variable. Exiting."
							exit 1
						fi

						cmd='--api_key $APPDOME_API_KEY \
							--app "$app_file" \
							--fusion_set_id $fusion_set_id \
							$tm \
							$sign_command \
							--keystore $keystore_file \
							--keystore_pass "$keystore_pass" \
							--keystore_alias "$keystore_alias" \
							$gp \
							$bl \
							$btv \
							$so \
							--key_pass "$private_key_password" \
							$dso \
							$dd \
							$aid \
							$wol \
							--output "$secured_app_output" \
							--certificate_output "$certificate_output"'
						if [[ $APPDOME_DEBUG == "1" ]]; then
							debug
						fi
						;;
esac

./appdome_api.sh $cmd

# rm -rf appdome-api-bash
if [[ $secured_app_output == *.sh ]]; then
	envman add --key APPDOME_PRIVATE_SIGN_SCRIPT_PATH --value $secured_app_output
elif [[ $secured_app_output == *.apk ]]; then
	envman add --key APPDOME_SECURED_APK_PATH --value $secured_app_output
else
	envman add --key APPDOME_SECURED_AAB_PATH --value $secured_app_output
	if [[ -n $so ]]; then
		envman add --key APPDOME_SECURED_SO_PATH --value $secured_so_app_output
	fi
fi

if [[ -n $dso ]]; then 
	envman add --key APPDOME_DEOB_MAPPING_FILES --value $BITRISE_DEPLOY_DIR/deobfuscation_mapping_files.zip
fi

if [[ -n $wol ]]; then 
	envman add --key APPDOME_WORKFLOW_LOGS --value $BITRISE_DEPLOY_DIR/$workflow_output_logs
fi

envman add --key APPDOME_CERTIFICATE_PATH --value $certificate_output

cd $PWD/..
pwd=$PWD
cd $PWD/..
rm -rf $pwd
