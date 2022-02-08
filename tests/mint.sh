NFT_ROOT_ABI="../src/compiled/NftRoot.abi.json"
NFT_ROOT_TVC="../src/compiled/NftRoot.tvc"
NFT_ROOT_DECODED="../src/compiled/NftRoot.decoded"
NFT_ABI="../src/compiled/Nft.abi.json"
NFT_TVC="../src/compiled/Nft.tvc"
NFT_DECODED="../src/compiled/Nft.decoded"
INDEX_DECODED="../src/compiled/Index.decoded"
INDEX_ABI="../src/compiled/Index.abi.json"
SETCODE_ABI="./SetcodeMultisigWallet.abi.json"
KEYS="deploy.keys.json"

TON_CLI="/root/tools/cli/target/release/tonos-cli"
TON_COMPILER="/root/.tondev/solidity/solc"
TVM_LINKER="/root/.tondev/solidity/tvm_linker"
TVM_LINKER_STDLIB="/root/.tondev/solidity/stdlib_sol.tvm"

LOCALNET="http://188.227.35.77/"

nft_root_addr="0:2ac86600adffe49a67fd9e06a6fba0f05912fc48173ddedb7af720bd1aed0393"
setcode_addr="0:343ddd4ed17a762aeffb3b60c8fcbbb43fbbddd7afa58050e0ec6ef434ddcfc2"
nft_addr="0:e916653e9eae69a81e6f26ad6995fe4b42fde4f5bd971f5ccbe411dc4203e39c"

mint=$($TON_CLI body --abi $NFT_ROOT_ABI mintNft '{}' | grep "Message body: " | awk '{split($0,a,": "); print a[2]}')
transfer=$($TON_CLI body --abi $NFT_ABI transferOwnership '{"callbackAddr": "0:0000000000000000000000000000000000000000000000000000000000000000", "sendGasToAddr": "0:0000000000000000000000000000000000000000000000000000000000000000", "addrTo": "0:488921925e7f2d103ba1fd0af0552f180ea94ce0df7b6f82eed69d27e7882106", "payload": ""}' | grep "Message body: " | awk '{split($0,a,": "); print a[2]}')

# $TON_CLI --url $LOCALNET call $setcode_addr submitTransaction '{"dest":"'$nft_root_addr'","value":2000000000,"bounce":true,"allBalance":false,"payload":"'$mint'"}' --abi $SETCODE_ABI --sign $KEYS
$TON_CLI --url $LOCALNET call $setcode_addr submitTransaction '{"dest":"'$nft_addr'","value":2000000000,"bounce":true,"allBalance":false,"payload":"'$transfer'"}' --abi $SETCODE_ABI --sign $KEYS

$TON_CLI --url $LOCALNET run $nft_addr getOwner '{"_answer_id": 0}' --abi $NFT_ABI

# $TON_CLI decode body --abi $INDEX_ABI "te6ccgEBAQEAKAAAS0dWVNyABVkMwBW//JNM/7PA1N90HgsiX4kC57vbb17kF6NdoHJw"