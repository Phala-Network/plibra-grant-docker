#!/usr/bin/env bash

echo "-----------start blockchain----------"
cd /root/phala-blockchain/node && sh ./scripts/console.sh purge
cd /root/phala-blockchain/node && sh ./scripts/console.sh start alice  > /root/alice.out &
cd /root/phala-blockchain/node && sh ./scripts/console.sh start bob > /root/bob.out &

echo "------------start pruntime----------"
cd /root/phala-pruntime/bin && ./app > /root/pruntime.out &

sleep 1

if [ ! -f "/tmp/alice/chains/local_testnet/genesis-info.txt" ]; then
    echo "WARNING! no genesis-info.txt"
fi

echo "-------------start phost-------------"
cd /root/phala-blockchain/phost && ./target/release/phost > /root/phost.out &

tail -f /root/alice.out /root/bob.out /root/pruntime.out /root/phost.out
