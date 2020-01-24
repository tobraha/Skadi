#!/bin/bash
echo "Installing / Updating / Configuring the following:"
echo "  -Change hostname to 'skadi'"
echo "  -CDQR"
echo "  -CyLR"
echo "  -Docker"
echo "  -Plaso"
echo "  -Mono"
echo "  -ELK"
echo "    -Elasticsearch"
echo "    -Logstash"
echo "    -Kibana"
echo "  -Redis"
echo "  -Neo4j"
echo "  -Celery"
echo "  -Timesketch"
echo "  -Cerebro"
echo "  -Other Dependancies"
echo "    -vim"
echo "    -openssh-server"
echo "    -curl"
echo "    -software-properties-common"
echo "    -unzip"
echo "    -htop"
echo "    -ca-certificates"
echo "    -apt-transport-https"
echo ""
echo "All usernames and passwords are made dynamically at run time"
echo "These are displayed at the end of the script (record them for use)"
echo ""
echo "*********** WARNING ***********"
echo "root or sudo privileges are required for this installation"
echo "*********** WARNING ***********"
echo ""
read -n 1 -r -s -p "Press any key to continue... or CTRL+C to exit (nothing has been installed)"
echo ""
echo ""

tempdir=$(mktemp -d)
buildskadi_tgz="$tempdir/buildskadi.tgz"
pubkey="MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvkxdzBSV1dTmcYrutrofEo2i9NvOPTnBItGAYQJOmx+rz10nrjbo6SWYqmgnV1eup3fZO2l0KYrpdUzTp1tBJDYbTXY0OpM64jDByaqVVUL83EGHfYcdAvGDYEziRcGjD+xKA0lMolDwaBWi9xfIbaCFIVkDIOcL6D/dCxh5/mLfsRivP91Bb3vTr1J/OVfJeI0ZzuNDPaaBef6oSZZ53phnlBN3qRSPODJHoLrl8ozuiIpc7s6k2CNNt/Dda3upos9PQsRgzlUl70qhCgRMmROdsLQee0PlTIjmoIext3boHZ/U1tGsBbfTpzb+NSWwUF1eW0Mq6+Uw1NBOcQNaAwIDAQAB"
buildskadi_pem="$tempdir/buildskadi.pem"
buildskadi_sig="$tempdir/buildskadi.sig"
buildskadi_sh="$tempdir/signedbuildskadi.sh"
update_sh="$tempdir/update.sh"

# Verify wget is installed and attempt to install it if it is missing
which wget > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Warning: wget is not installed. Attempting to install wget"
  sudo apt install wget -y
  if [ $? -ne 0 ]; then
    echo "ERROR: Unable to install wget. Exiting"
    rm -rf $tempdir
    exit 1
  fi
fi

# Download install file and verify it was successful
wget -O $buildskadi_tgz --quiet https://raw.githubusercontent.com/albchen/skadi/master/scripts/buildskadi.tgz
if [ $? -ne 0 ]; then
  echo "ERROR: Download was not successful. Exiting"
  rm -rf $tempdir
  exit 1
fi

# Download signature file and verify it was successful
wget -O $buildskadi_sig --quiet https://raw.githubusercontent.com/albchen/skadi/master/scripts/buildskadi.sig
if [ $? -ne 0 ]; then
  echo "ERROR: Download was not successful. Exiting"
  rm -rf $tempdir
  exit 1
fi

# Verify openssl is installed and attempt to install it if it is missing
which openssl > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Warning: openssl is not installed. Attempting to install openssl"
  sudo apt install -y openssl
  if [ $? -ne 0 ]; then
    echo "ERROR: Unable to install openssl. Exiting"
    rm -rf $tempdir
    exit 1
  fi
fi

# Verify installation files using openssl
echo $pubkey |base64 -d > $buildskadi_pem
verify=$(openssl dgst -sha256 -verify $buildskadi_pem -signature $buildskadi_sig $buildskadi_tgz)

if [ "$verify" == "Verified OK" ]; then
  echo "OpenSSL digital signature verified; launching installation"
  echo ""
  echo ""
else
  echo "ERROR: Unable to verify installation file. Exiting"
  rm -rf $tempdir
  exit 1
fi

# Extract verified installation file and execute it
tar xzf $buildskadi_tgz -C $tempdir
chmod +x $buildskadi_sh
DEBIAN_FRONTEND=noninteractive $buildskadi_sh

# Remove all files associated with build
rm -rf $tempdir
exec bash
