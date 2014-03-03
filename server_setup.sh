#!/bin/bash

set -e

# Parse option flags.
if [[ $1 = "-d" ]]; then
  echo "DEV MODE"
  export CDO_DEV=1
  shift
fi

# Parse positional arguments.
if [[ $# -lt 3 ]]; then
  echo 'Usage: server_setup.sh [options] <dash_root> <cdo_user> <rails_env>'
  exit 1
fi
export DASH_ROOT=$1
export CDO_USER=$2
export RAILS_ENV=$3

export DEBIAN_FRONTEND=noninteractive
aptitude update

# Native dependencies for builds with Node.js.
if [[ $CDO_DEV ]]; then
  aptitude -y install \
    libcairo2-dev \
    libjpeg8-dev \
    libpango1.0-dev \
    libgif-dev \
    g++
fi

bundle install --gemfile=$DASH_ROOT/Gemfile --binstubs

# Configure Unicorn
unicorn_cfg=/etc/init.d/unicorn
rm -f $unicorn_cfg
sed -e "s|%DASH_ROOT%|$DASH_ROOT|g" \
    -e "s|%CDO_USER%|$CDO_USER|g" \
    -e "s|%RAILS_ENV%|$RAILS_ENV|g" \
    $DASH_ROOT/config/unicorn_init.sh > $unicorn_cfg
chmod +x $unicorn_cfg
$DASH_ROOT/config/unicorn.rb.sh > $DASH_ROOT/config/unicorn.rb
mkdir -p /var/log/unicorn
chown $CDO_USER /var/log/unicorn
/usr/sbin/update-rc.d -f unicorn defaults

# Configure Nginx
$DASH_ROOT/scripts/cfg_nginx

# configure logrotate
cp $DASH_ROOT/config/logrotate /etc/logrotate.d/cdo
logrotate /etc/logrotate.d/cdo

