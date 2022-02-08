NFT_ROOT_ABI="../src/compiled/NftRoot.abi.json"
NFT_ROOT_TVC="../src/compiled/NftRoot.tvc"
NFT_ROOT_DECODED="../src/compiled/NftRoot.decoded"
NFT_ABI="../src/compiled/Nft.abi.json"
NFT_TVC="../src/compiled/Nft.tvc"
NFT_DECODED="../src/compiled/Nft.decoded"
INDEX_DECODED="../src/compiled/Index.decoded"
KEYS="deploy.keys.json"

TON_CLI="/root/tools/cli/target/release/tonos-cli"
TON_COMPILER="/root/.tondev/solidity/solc"
TVM_LINKER="/root/.tondev/solidity/tvm_linker"
TVM_LINKER_STDLIB="/root/.tondev/solidity/stdlib_sol.tvm"

LOCALNET="http://188.227.35.77/"

ADDR_ROOT=$($TON_CLI genaddr --setkey $KEYS --wc 0 $NFT_ROOT_TVC $NFT_ROOT_ABI | grep "Raw address: " | awk '{split($0,a,": "); print a[2]}')
echo $ADDR_ROOT

codeIndex=$(cat $INDEX_DECODED)
codeNft=$(cat $NFT_DECODED)
ownerPubkey="d29df6a3d24705c6bb862e8b0d7c482085b320d143849553ba88895ccfbc58b2"

deploy_params='{
                    "codeIndex": "'$codeIndex'",
                    "codeNft": "'$codeNft'",
                    "ownerPubkey": "0x'$ownerPubkey'"
                }'

$TON_CLI --url $LOCALNET deploy $NFT_ROOT_TVC "$deploy_params" --abi $NFT_ROOT_ABI --sign $KEYS --wc 0

#0:2ac86600adffe49a67fd9e06a6fba0f05912fc48173ddedb7af720bd1aed0393