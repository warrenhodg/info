#!/bin/bash

POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case "$key" in
    -c|--context)
      CONTEXT=$2
      shift
      shift
      ;;
    -d|--dir)
      DIR=$2
      shift
      shift
      ;;
    -l|--local-port)
      LOCAL_PORT=$2
      shift
      shift
      ;;
    -n|--namespace)
      NAMESPACE=$2
      shift
      shift
      ;;
    -p|--pod)
      POD=$2
      shift
      shift
      ;;
    -r|--remote-port)
      REMOTE_PORT=$2
      shift
      shift
      ;;
    -s|--seconds)
      SECONDS=$2
      shift
      shift
      ;;
    -u|--url-endpoint)
      URLENDPOINT=$2
      shift
      shift
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

usage() {
  echo -e "$0 \\"
  echo -e "\t[-c context (default=current)] \\"
  echo -e "\t[-d dir (default=.)] \\"
  echo -e "\t[-l local_port (default=remote_port)] \\"
  echo -e "\t[-n namespace (default=default)] \\"
  echo -e "\t-p pod \\"
  echo -e "\t[-r remote_port (default=6060)] \\"
  echo -e "\t[-s seconds (default=application default)] \\"
  echo -e "\t[-u url_endpoint (default=debug/pprof)]"
}

[[ -z $POD ]] && echo "pod not specified" && usage && exit 1
[[ -z $DIR ]] && DIR="."
[[ ! -z $CONTEXT ]] && CONTEXT="--context $CONTEXT"
[[ ! -z $NAMESPACE ]] && NAMESPACE="-n $NAMESPACE"
[[ ! -z $SECONDS ]] && SECONDS="?seconds=$SECONDS"
[[ -z $REMOTE_PORT ]] && REMOTE_PORT=6060
[[ -z $LOCAL_PORT ]] && LOCAL_PORT=$REMOTE_PORT
[[ -z $URLENDPOINT ]] && URLENDPOINT="debug/pprof"
TIMESTAMP=$(date "+%Y-%m-%d-%H%M%S")

mkdir -p "$DIR/$TIMESTAMP"
echo "kubectl $CONTEXT port-forward $POD $NAMESPACE $LOCAL_PORT:$REMOTE_PORT" &
kubectl ${CONTEXT} port-forward $POD $NAMESPACE $LOCAL_PORT:$REMOTE_PORT &
KUBE_PID=$!
# I'd like something better than sleep to wait until the port forwarding is
# actually up, but am not sure of the best way to do this from bash
sleep 10

curl http://127.0.0.1:$LOCAL_PORT/$URLENDPOINT/allocs -o "$DIR/$TIMESTAMP/allocs.pprof"
curl http://127.0.0.1:$LOCAL_PORT/$URLENDPOINT/block -o "$DIR/$TIMESTAMP/block.pprof"
curl http://127.0.0.1:$LOCAL_PORT/$URLENDPOINT/cmdline -o "$DIR/$TIMESTAMP/cmdline.pprof"
curl http://127.0.0.1:$LOCAL_PORT/$URLENDPOINT/goroutine -o "$DIR/$TIMESTAMP/goroutine.pprof"
curl http://127.0.0.1:$LOCAL_PORT/$URLENDPOINT/heap -o "$DIR/$TIMESTAMP/heap.pprof"
curl http://127.0.0.1:$LOCAL_PORT/$URLENDPOINT/mutex -o "$DIR/$TIMESTAMP/mutex.pprof"
curl http://127.0.0.1:$LOCAL_PORT/$URLENDPOINT/profile$SECONDS -o "$DIR/$TIMESTAMP/profile.pprof"
curl http://127.0.0.1:$LOCAL_PORT/$URLENDPOINT/threadcreate$SECONDS -o "$DIR/$TIMESTAMP/threadcreate.pprof"
curl http://127.0.0.1:$LOCAL_PORT/$URLENDPOINT/trace$SECONDS -o "$DIR/$TIMESTAMP/trace.pprof"

tar -czf "$DIR/$TIMESTAMP.tgz" "$DIR/$TIMESTAMP"
rm -rf "$DIR/$TIMESTAMP"
echo "saved $DIR/$TIMESTAMP.tgz"

kill $KUBE_PID
