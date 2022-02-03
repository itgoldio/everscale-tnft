#!/bin/bash

TON_CLI="/root/tools/cli/target/release/tonos-cli"
TON_COMPILER="/root/.tondev/solidity/solc"
TVM_LINKER="/root/.tondev/solidity/tvm_linker"
TVM_LINKER_STDLIB="/root/.tondev/solidity/stdlib_sol.tvm"

# contracts=("Nft" "NftRoot")
contracts=("Index" "IndexBasis" "Nft" "NftRoot")

for i in ${!contracts[*]}
do
  CONTRACT_NAME=${contracts[$i]}

  $TON_COMPILER $CONTRACT_NAME.sol
  $TVM_LINKER compile $CONTRACT_NAME.code --lib $TVM_LINKER_STDLIB -o $CONTRACT_NAME.tvc

  CONTRACT_DECODED=$($TVM_LINKER decode --tvc $CONTRACT_NAME.tvc | grep "code:" | awk '{split($0,a,": "); print a[2]}')

  echo $CONTRACT_DECODED > $CONTRACT_NAME.decoded

  CONTRACT_HASH=$($TVM_LINKER decode --tvc $CONTRACT_NAME.tvc | grep "code_hash:" | awk '{split($0,a,": "); print a[2]}')

  echo $CONTRACT_HASH > $CONTRACT_NAME.hash

done