#!/bin/bash

# logging functions
syncpvc_log() {
	local type="$1"; shift
	printf '%s [%s] [Entrypoint]: %s\n' "$(date --rfc-3339=seconds)" "$type" "$*"
}
syncpvc_note() {
	syncpvc_log Note "$@"
}
syncpvc_warn() {
	syncpvc_log Warn "$@" >&2
}
syncpvc_error() {
	syncpvc_log ERROR "$@" >&2
	exit 1
}

# Verify rsync is present on remote container
is_rsync() {

  local container=$1
  local rsync_bin="/usr/bin/rsync"

  local pod=$( oc get pod -l name=$container -o name | head -1 )  

  if ! oc rsh $pod -c $container test -f $rsync_bin
  then
    syncpvc_error $'rsync binary not found in '$rsync_bin 
  fi

}

# Verify that the minimally required settings are set 
verify_minimum_env() {
	if [ -z "$RSYNC_SOURCE" -a -z "$TOKEN" -a -z "$NAMESPACE" -a -z "$APPNAME" ]; then
		syncpvc_error $'You need to specify RSYNC_SOURCE, TOKEN, NAMESPACE, APPNAME'
	fi
}

main () {

  local src_path="$RSYNC_SOURCE"
  local dst_path="$RSYNC_DEST"
  local token="$TOKEN"
  local namespace="$NAMESPACE"
  local app="$APPNAME"

  echo "oc login --token"
  if ! oc login --token=$token
  then
      syncpvc_error $'Unable to login using the provided token '$token
  fi

  echo "oc project $namespace"
  if ! oc project $namespace
  then
      syncpvc_error $'Namespace '$namespace' not found'
  fi

  echo "is_rsync $app"
  is_rsync $app

  local pod=$( oc get pod -l name=$app -o name | head -1 )  
  echo "oc rsync ${pod}:$src_path $dst_path"
  oc rsync --progress=true ${pod}:$src_path $dst_path

}

main "$@"

