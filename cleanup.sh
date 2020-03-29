#!/bin/bash

function rm_expect {
  rm -rf /tmp/rmbak
  mkdir /tmp/rmbak
  TARGET="$1"
  shift
  pushd "$TARGET"
  cp -r "$@" /tmp/rmbak
  popd
  rm -rf "$TARGET"
  mkdir -p "$TARGET"
  mv /tmp/rmbak/* "$TARGET"
  rm -rf /tmp/rmbak
}

# blockchain
rm_expect ./phala-blockchain/node/target/release phala-blockchain

# phost
rm_expect ./phala-blockchain/phost/target/release phost

# pRuntime
rm -rf ./phala-pruntime/enclave/target
rm -rf ./phala-pruntime/app/target
