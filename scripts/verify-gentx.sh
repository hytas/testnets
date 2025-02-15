#!/bin/bash
NETWORK=nibiru-2000
MAX_BOND=100000000000

extraquery='[.body.messages[] | select(."@type" != "/cosmos.staking.v1beta1.MsgCreateValidator")] | length'

gentxquery='.body.messages[] | select(."@type" = "/cosmos.staking.v1beta1.MsgCreateValidator") | .value'

denomquery="[$gentxquery | select(.denom != \"game\")] | length"

amountquery="$gentxquery | .amount"

for path in $NETWORK/gentxs/*.json; do
  echo $path
  # only allow MsgCreateValidator transactions.
  if [ "$(jq "$extraquery" "$path")" != "0" ]; then
    echo "spurious transactions"
    exit 1
  fi

  # only allow "game" tokens to be bonded
  if [ "$(jq "$denomquery" "$path")" != "0" ]; then
    echo "invalid denomination"
    exit 1
  fi

  # limit the amount that can be bonded
  for amount in "$(jq -rM "$amountquery" "$path")"; do
    amt="$amount"
    if [ $amt -gt $MAX_BOND ]; then
      echo "bonded too much: $amt > $MAX_BOND"
      exit 1
    fi
  done
done

exit 0
