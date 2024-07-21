#!/bin/bash
set -e
# file version: RS-A-3.5
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

debug () {
	echo "Debugger:" > $BITRISE_DEPLOY_DIR/debug.txt
	echo "Keystore file: $keystore_file" >> $BITRISE_DEPLOY_DIR/debug.txt
	echo "Keystore alias: $keystore_alias" >> $BITRISE_DEPLOY_DIR/debug.txt
	echo "FP: $gp" >> $BITRISE_DEPLOY_DIR/debug.txt
	echo "SF: $sf" >> $BITRISE_DEPLOY_DIR/debug.txt 
	echo "BL: $bl" >> $BITRISE_DEPLOY_DIR/debug.txt 
	echo "BTV: $btv" >> $BITRISE_DEPLOY_DIR/debug.txt 
	echo "SO: $so" >> $BITRISE_DEPLOY_DIR/debug.txt 

	ls -al >> $BITRISE_DEPLOY_DIR/debug.txt
	ls -al .. >> $BITRISE_DEPLOY_DIR/debug.txt
	echo >> $BITRISE_DEPLOY_DIR/debug.txt
	echo --api_key $APPDOME_API_KEY \
		--app $app_file \
		--fusion_set_id $fusion_set_id \
		$tm \
		--sign_on_appdome \
		--keystore $keystore_file \
		--keystore_pass $keystore_pass \
		--keystore_alias $keystore_alias \
		$gp \
		$sf \
		$bl \
		$btv \
		$so \
		--key_pass $key_pass \
		--output $secured_app_output \
		--certificate_output $certificate_output >> $BITRISE_DEPLOY_DIR/debug.txt
}

print_all_params() {
	echo "Appdome Build-2Secure parameters:"
	echo "=================================="
	echo "App location: $app_location"
	echo "Output file: $secured_app_output"
	echo "Team ID: $team_id"
	echo "Sign Method: $sign_method"
	echo "Keystore file: $keystore_file" 
	echo "Keystore password: $ks_pass" 
	echo "Keystore alias: $keystore_alias" 
	echo "Key password: $private_key_password" 
	echo "Google Play Singing: $gp_signing"
	echo "Google Fingerprint: $GOOGLE_SIGN_FINGERPRINT" 
	echo "Sign Fingerprint: $SIGN_FINGERPRINT"
	echo "Build with logs: $build_logs" 
	echo "Build to test: $build_to_test" 
	echo "Secured app output: $secured_app_output"
	echo "Certificate output: $certificate_output"
	echo "Secondary output: $secured_so_app_output"
	echo "-----------------------------------------"
}

download_file() {
	file_location=$(echo "$1" | tr -cd '\000-\177')
	uri=$(echo $file_location | awk -F "?" '{print $1}')
	downloaded_file=$(basename $uri)
	curl -L $file_location --output $downloaded_file && echo $downloaded_file
}

internal_version="RS-A-3.6"
echo "Internal version: $internal_version"
export APPDOME_CLIENT_HEADER="Bitrise/3.6.0"

app_location=$1
fusion_set_id=$2
team_id=$3
sign_method=$4
certificate_file=$5
keystore_password=$6
keystore_alias=$7
private_key_password=$8
gp_signing=$9
google_fingerprint=${10}
fingerprint=${11}
build_logs=${12}
build_to_test=${13}
secondary_output=${14}
output_filename=${15}
app_id=""
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
if [[ -n $GOOGLE_APPLICATION_CREDENTIALS ]]; then
	if [[ $GOOGLE_APPLICATION_CREDENTIALS == *"http"* ]]; then
		GOOGLE_APPLICATION_CREDENTIALS=../$(download_file $GOOGLE_APPLICATION_CREDENTIALS)
	else
		google_service_file=$GOOGLE_APPLICATION_CREDENTIALS
		if [[ $google_service_file == *" "* ]];	then
			GOOGLE_APPLICATION_CREDENTIALS=${GOOGLE_APPLICATION_CREDENTIALS//" "/"_"}
			cp "$google_service_file" "$GOOGLE_APPLICATION_CREDENTIALS"
		fi
	fi
	envman add --key GOOGLE_APPLICATION_CREDENTIALS --value $GOOGLE_APPLICATION_CREDENTIALS
	if [[ -n $app_id ]]; then 
		aid="-aid $app_id"
	fi
else
	echo "WARNING: GOOGLE_APPLICATION_CREDENTIALS file was not provided, deobfuscation map will not be uploaded to Crashlytics." 
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

sf=""
if [[ -n $fingerprint ]]; then
	sf="--signing_fingerprint ${fingerprint}"
fi

gp=""
if [[ $gp_signing == "true" ]]; then
	if [[ -z $google_fingerprint ]]; then
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
	btv="--build_to_test_vendor  $build_to_test"
fi

dso="-dso $BITRISE_DEPLOY_DIR/deobfuscation_mapping_files.zip"

case $sign_method in
"Private-Signing")		
						print_all_params
						echo "Private Signing"
						./appdome_api.sh --api_key $APPDOME_API_KEY \
							--app $app_file \
							--fusion_set_id $fusion_set_id \
							$tm \
							--private_signing \
							$gp \
							$sf \
							$bl \
							$btv \
							$so \
							$dso \
							$aid \
							--output "$secured_app_output" \
							--certificate_output $certificate_output 
						;;
"Auto-Dev-Signing")		
						echo "Auto Dev Signing"
						secured_app_output_name=${secured_app_output%.*}
						secured_app_output=$secured_app_output_name.sh
						print_all_params
						./appdome_api.sh --api_key $APPDOME_API_KEY \
							--app $app_file \
							--fusion_set_id $fusion_set_id \
							$tm \
							--auto_dev_private_signing \
							$gp \
							$sf \
							$bl \
							$btv \
							$dso \
							$aid \
							--output "$secured_app_output" \
							--certificate_output $certificate_output 
						;;
"On-Appdome")			
						if [[ $certificate_file == "_@_" ]]; then
							if [[ -n $BITRISEIO_ANDROID_KEYSTORE_URL ]]; then
								certificate_file=$BITRISEIO_ANDROID_KEYSTORE_URL
								keystore_pass=$BITRISEIO_ANDROID_KEYSTORE_PASSWORD
								private_key_password=$BITRISEIO_ANDROID_KEYSTORE_PRIVATE_KEY_PASSWORD
								keystore_alias=$BITRISEIO_ANDROID_KEYSTORE_ALIAS
							else
								if [[ -n $BITRISEIO_ANDROID_KEYSTORE_1_URL ]]; then
									certificate_file=$BITRISEIO_ANDROID_KEYSTORE_1_URL
									keystore_pass=$BITRISEIO_ANDROID_KEYSTORE_1_PASSWORD
									private_key_password=$BITRISEIO_ANDROID_KEYSTORE_PRIVATE_1_KEY_PASSWORD
									keystore_alias=$BITRISEIO_ANDROID_KEYSTORE_1_ALIAS
								else
									echo "Could not find keystore file. Please recheck Android keystore file environment variable. Exiting."
									exit 1
								fi
							fi
						fi

						keystore_file=$(download_file $certificate_file)
						ks_pass=""
						if [[ -n $keystore_pass ]]; then
							ks_pass=$keystore_pass
						fi
												
						print_all_params

						if [[ ! -s $keystore_file ]]; then
							echo "Failed obtaining keystore file. Please recheck Android keystore file environment variable. Exiting."
							exit 1
						fi
						if [[ -z $keystore_pass ]]; then
							echo "Could not find keystore password. Please recheck Android keystore file environment variable. Exiting."
							exit 1
						fi
						if [[ -z $keystore_alias ]]; then
							echo "Could not find keystore alias. Please recheck Android keystore file environment variable. Exiting."
							exit 1
						fi
						if [[ -z $private_key_password ]]; then
							echo "Could not find keystore private key password. PPlease recheck Android keystore file environment variable. Exiting."
							exit 1
						fi


						echo "On Appdome Signing"
						./appdome_api.sh --api_key $APPDOME_API_KEY \
							--app $app_file \
							--fusion_set_id $fusion_set_id \
							$tm \
							--sign_on_appdome \
							--keystore $keystore_file \
							--keystore_pass "$keystore_pass" \
							--keystore_alias "$keystore_alias" \
							$gp \
							$bl \
							$btv \
							$so \
							--key_pass "$private_key_password" \
							$dso \
							$aid \
							--output "$secured_app_output" \
							--certificate_output $certificate_output 
						;;
esac


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

envman add --key APPDOME_CERTIFICATE_PATH --value $certificate_output

cd $PWD/..
pwd=$PWD
cd $PWD/..
rm -rf $pwd