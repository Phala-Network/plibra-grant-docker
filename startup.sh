#!/usr/bin/env bash

nginx -s reload

echo "-----------start blockchain----------"
cd /root/phala-blockchain/node && bash ./scripts/console.sh purge
cd /root/phala-blockchain/node && bash ./scripts/console.sh start alice  > /root/alice.out 2>&1 &
cd /root/phala-blockchain/node && bash ./scripts/console.sh start bob > /root/bob.out 2>&1 &

echo "------------start pruntime----------"
cd /root/phala-pruntime/bin && ./app > /root/pruntime.out 2>&1 &

sleep 1

if [ ! -f "/tmp/alice/chains/local_testnet/genesis-info.txt" ]; then
    echo "WARNING! no genesis-info.txt"
fi

echo "-------------start phost-------------"
cd /root/phala-blockchain/phost && ./target/release/phost > /root/phost.out 2>&1 &

tail -f /root/alice.out /root/bob.out /root/pruntime.out /root/phost.out
