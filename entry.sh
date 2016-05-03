#!/usr/bin/env bash

set -e
[ "${DEBUG:-false}" == 'true' ] && set -x

mount --rbind /host/dev /dev

echo "Running command $@"
exec "$@"
