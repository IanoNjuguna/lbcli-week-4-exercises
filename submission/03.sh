#!/usr/bin/bash
# Create a raw transaction and add this message in it: "btrust builder 2026"

# Amount of 20,000,000 satoshis to this address: 2MvLcssW49n9atmksjwg2ZCMsEMsoj3pzUP 
# Use the UTXOs from the transaction below
RAW_TX="01000000000101c8b0928edebbec5e698d5f86d0474595d9f6a5b2e4e3772cd9d1005f23bdef772500000000ffffffff0276b4fa0000000000160014f848fe5267491a8a5d32423de4b0a24d1065c6030e9c6e000000000016001434d14a23d2ba08d3e3edee9172f0c97f046266fb0247304402205fee57960883f6d69acf283192785f1147a3e11b97cf01a210cf7e9916500c040220483de1c51af5027440565caead6c1064bac92cb477b536e060f004c733c45128012102d12b6b907c5a1ef025d0924a29e354f6d7b1b11b5a7ddff94710d6f0042f3da800000000"

# 1. Silently ensure the wallet is loaded
bitcoin-cli -regtest loadwallet "btrust" > /dev/null 2>&1

# 3. Extract the parent transaction data using jq
TX_TXID=$(bitcoin-cli -regtest decoderawtransaction $RAW_TX | jq -r '.txid')
VAL_0=$(bitcoin-cli -regtest decoderawtransaction $RAW_TX | jq -r '.vout[0].value')
VAL_1=$(bitcoin-cli -regtest decoderawtransaction $RAW_TX | jq -r '.vout[1].value')

# 4. Settings & Logic
DEST_ADDR="2MvLcssW49n9atmksjwg2ZCMsEMsoj3pzUP"
AMOUNT=0.2
FEE=0.0001

# Convert our message "btrust builder 2026" to hexadecimal
MSG_HEX=$(echo -n "btrust builder 2026" | xxd -p)

# 5. Dynamic change parameters (explicit wallet routing)
CHANGE_ADDR=$(bitcoin-cli -regtest -rpcwallet=btrustwallet getnewaddress)
CHANGE_AMOUNT=$(echo "$VAL_0 + $VAL_1 - $AMOUNT - $FEE" | bc | awk '{printf "%.8f\n", $0}')

# 6. Build the raw transaction with the "data" output
bitcoin-cli -regtest createrawtransaction "[
  {
    \"txid\": \"$TX_TXID\",
    \"vout\": 0
  },
  {
    \"txid\": \"$TX_TXID\",
    \"vout\": 1
  }
]" "[
  {
    \"$DEST_ADDR\": $AMOUNT
  },
  {
    \"$CHANGE_ADDR\": $CHANGE_AMOUNT
  },
  {
    \"data\": \"$MSG_HEX\"
  }
]"
