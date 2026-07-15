#!/usr/bin/bash
# Create a raw transaction that can be spent in 2 weeks time, assuming the current block is 25

# Amount of 20,000,000 satoshis to this address: 2MvLcssW49n9atmksjwg2ZCMsEMsoj3pzUP 
# Use the UTXOs from the transaction below
RAW_TX="01000000000101c8b0928edebbec5e698d5f86d0474595d9f6a5b2e4e3772cd9d1005f23bdef772500000000ffffffff0276b4fa0000000000160014f848fe5267491a8a5d32423de4b0a24d1065c6030e9c6e000000000016001434d14a23d2ba08d3e3edee9172f0c97f046266fb0247304402205fee57960883f6d69acf283192785f1147a3e11b97cf01a210cf7e9916500c040220483de1c51af5027440565caead6c1064bac92cb477b536e060f004c733c45128012102d12b6b907c5a1ef025d0924a29e354f6d7b1b11b5a7ddff94710d6f0042f3da800000000"

bitcoin-cli -regtest loadwallet "btrustwallet" > /dev/null 2>&1

# Extract the TXID
TX_TXID=$(bitcoin-cli -regtest decoderawtransaction $RAW_TX | jq -r '.txid')

# Extract the values of vout 0 and vout 1
VAL_0=$(bitcoin-cli -regtest decoderawtransaction $RAW_TX | jq -r '.vout[0].value')
VAL_1=$(bitcoin-cli -regtest decoderawtransaction $RAW_TX | jq -r '.vout[1].value')

# Calculate target block (Current block 25 + 2016 blocks for 2 weeks)
LOCKTIME=$((25 + 2016))

# Sequence for timelock
SEQ=4294967294

# Destination Details
DEST_ADDR="2MvLcssW49n9atmksjwg2ZCMsEMsoj3pzUP"
AMOUNT=0.2
FEE=0.0001

# Calculate Change Amount using 'bc' (since bash doesn't do floating-point math natively)
CHANGE_AMOUNT=$(echo "$VAL_0 + $VAL_1 - $AMOUNT - $FEE" | bc | awk '{printf "%.8f\n", $0}')
CHANGE_ADDR=$(bitcoin-cli -regtest getnewaddress)

bitcoin-cli -regtest createrawtransaction "[
  {
    \"txid\": \"$TX_TXID\",
    \"vout\": 0,
    \"sequence\": $SEQ
  },
  {
    \"txid\": \"$TX_TXID\",
    \"vout\": 1,
    \"sequence\": $SEQ
  }
]" "{
  \"$DEST_ADDR\": $AMOUNT,
  \"$CHANGE_ADDR\": $CHANGE_AMOUNT
}" $LOCKTIME

