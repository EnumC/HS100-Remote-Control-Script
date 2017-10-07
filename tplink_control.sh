#!/bin/sh
#
# TP-LINK Control Script
#
# Usage: ./tplink_control ON/OFF
#
#

############# CONFIG ################
# Change DEVICEID to the device you want to control
# by running ./tplink_control INIT_CONFIG
############# /CONFIG ################
if [ ! -f ~/.tplink.token ]; then
    echo "~/.tplink.token does NOT exist!"
    echo "Please run ./tplink_control INIT_CONFIG"
    echo
fi

test -f ~/.tplink.token && source ~/.tplink.token
COMMAND=$1
COMMAND=$(echo "$COMMAND" | awk '{print toupper($0)}')

echo

function generate_post_data {
  cat <<EOF
  {
    "method": "login",
    "params": {
    "appType": "Kasa_Android",
    "cloudUserName": "$username",
    "cloudPassword": "$password",
    "terminalUUID": "$uuid"
    }
  }
EOF
}
function getToken {
  curl -s -XPOST -H "Content-type: application/json" -d "$(generate_post_data)" 'https://wap.tplinkcloud.com' | jq '.'
}

function turnOn {
  request_body=$(cat <<EOF
{
  "method":"passthrough",
  "params": {
    "deviceId": "$deviceID",
    "requestData": "{\"system\":{\"set_relay_state\":{\"state\":1} } }"
  }
}
EOF
)
  curl -s -X POST -H "Content-Type: application/json" -d "$request_body" "https://use1-wap.tplinkcloud.com/?token=${TOKEN}" | jq '.'
}
function turnOff {
  request_body=$(cat <<EOF
{
  "method":"passthrough",
  "params": {
    "deviceId": "$deviceID",
    "requestData": "{\"system\":{\"set_relay_state\":{\"state\":0} } }"
  }
}
EOF
)
  curl -s -X POST -H "Content-Type: application/json" -d "$request_body" "https://use1-wap.tplinkcloud.com/?token=${TOKEN}" | jq '.'
}
function getDeviceInfo {
  curl -s --request POST "https://wap.tplinkcloud.com?token=${token} HTTP/1.1" \
   --data '{"method":"getDeviceList"}' \
   --header "Content-Type: application/json" | jq '.'
}

function checkToken {
  curl -s --request POST "https://wap.tplinkcloud.com?token=${token} HTTP/1.1" \
   --data '{"method":"getDeviceList"}' \
   --header "Content-Type: application/json" | grep '"error_code":0'>/dev/null
   if [ ! $? -eq 0 ]; then
     echo "***Error! Token Expired/Invalid. Please run ./tplink_control INIT_CONFIG***"
     echo
     exit 1
   fi

}

if [ "$COMMAND" = "INIT_CONFIG" ]
  then
    echo
    echo Generating Unique UUID...
    echo "uuid="$(uuidgen) >~/.tplink.token
    test -f ~/.tplink.token && source ~/.tplink.token
    echo "Generated UUID: $uuid"
    echo
    read -p "Enter Your API Username: "  username
    echo "Username: $username has been stored temporarily!"
    echo

    unset password
    unset charcount

    echo "Enter Your API Password: "

    stty -echo

    charcount=0

    while IFS= read -p "$PROMPT" -r -s -n 1 CHAR
    do
        # Enter - accept password
        if [[ $CHAR == $'\0' ]] ; then
            break
        fi
        # Backspace
        if [[ $CHAR == $'\177' ]] ; then
            if [ $charcount -gt 0 ] ; then
                charcount=$((charcount-1))
                PROMPT=$'\b \b'
                password="${password%?}"
            else
                PROMPT=''
            fi
        else
            charcount=$((charcount+1))
            PROMPT='*'
            password+="$CHAR"
        fi
    done

stty echo

    echo
    echo "Password has been stored temporarily!"
    echo
    if [ ! -f ~/.tplink.token ]; then
      echo "File Lookup Failed. Please make sure this program have access to ~/.tplink.token"
    else
      test -f ~/.tplink.token && source ~/.tplink.token
    fi
    echo "Here's the token: "
    getToken
    echo
    read -p "Enter The Authentication Token: "  input
    echo "Token: $input has been stored!"
    echo "token="$input >~/.tplink.token
    echo
    unset username
    unset password
    echo "Your username and password has been wiped!"
    echo
    if [ ! -f ~/.tplink.token ]; then
      echo "File Lookup Failed. Please make sure this program have access to ~/.tplink.token"
      exit 1
    else
      test -f ~/.tplink.token && source ~/.tplink.token
    fi
    echo "Here is the list of available devices: "
    getDeviceInfo
    echo
    read -p "Enter The deviceID Of The Switch You Want To Add: "  input
    echo "deviceID: $input has been stored!"
    echo "deviceID="$input >>~/.tplink.token
    exit 0
fi



if [[ -z "${token}" ]]; then
  echo "TPLINK_TOKEN: <${token}> IS INVALID!"
  echo "Something is wrong with your environment. Please make sure you are running bash!"
  echo "Please run ./tplink_control INIT_CONFIG to reinitialize!"
  exit 1
else
  TOKEN="${token}"
fi



checkToken
if [ "$COMMAND" = "" ]
  then
    echo 'Usage: ./tplink_control ON/OFF/GETTOKEN/GETDEVICEINFO/INIT_CONFIG'
  elif [ "$COMMAND" = "ON" ]
    then
      turnOn
  elif [ "$COMMAND" = "OFF" ]
    then
      turnOff
  elif [ "$COMMAND" = "GETTOKEN" ]
    then
      getToken
  elif [ "$COMMAND" = "GETDEVICEINFO" ]
    then
      getDeviceInfo
      echo
  else
    echo 'Usage: ./tplink_control ON/OFF/GETTOKEN/GETDEVICEINFO/INIT_CONFIG'
fi
echo
