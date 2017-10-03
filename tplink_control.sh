#!/bin/sh
#
# TP-LINK Control Script
#
# Usage: ./tplink_control ON/OFF
#
#
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
    "cloudUserName": "$user",
    "cloudPassword": "$pass",
    "terminalUUID": "6c831772-a3d2-42b7-9764-d65c9a978613"
    }
  }
EOF
}
function getToken {
  curl -s -XPOST -H "Content-type: application/json" -d "$(generate_post_data)" 'https://wap.tplinkcloud.com' | jq '.'
}
function turnOn {
  curl -s -X POST -H "Content-Type: application/json" -d '{
   "method":"passthrough",
   "params": {
   "deviceId": "800682E21A0CD5C7EEAD136D912CCAF71879F504",
   "requestData": "{\"system\":{\"set_relay_state\":{\"state\":1} } }"
 } }' "https://use1-wap.tplinkcloud.com/?token=${TOKEN}" | jq '.'
}
function turnOff {
  curl -s -X POST -H "Content-Type: application/json" -d '{
   "method":"passthrough",
   "params": {
   "deviceId": "800682E21A0CD5C7EEAD136D912CCAF71879F504",
   "requestData": "{\"system\":{\"set_relay_state\":{\"state\":0} } }"
 } }' "https://use1-wap.tplinkcloud.com/?token=${TOKEN}" | jq '.'
}
function getDeviceInfo {
  curl -s --request POST "https://wap.tplinkcloud.com?token=${TOKEN} HTTP/1.1" \
   --data '{"method":"getDeviceList"}' \
   --header "Content-Type: application/json" | jq '.'
}

if [ "$COMMAND" = "INIT_CONFIG" ]
  then

    echo
    read -p "Enter Your API Username: "  username
    echo "Username: $username has been stored!"
    echo "user="$username >~/.tplink.token
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
    echo "Password has been stored!"
    echo "pass="$password >>~/.tplink.token
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
    echo "token="$input >>~/.tplink.token
    echo

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




if [ "$COMMAND" = "" ]
  then
    echo 'Usage: ./tplink_control ON/OFF/GETTOKEN/GETDEVICEINFO'
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
    echo 'Usage: ./tplink_control ON/OFF/GETTOKEN/GETDEVICEINFO'
fi
echo
