pragma ton-solidity = 0.47.0;
pragma AbiHeader expire;

interface ITokenTransferCallback {
    function tokenTransferCallback(
        uint256 id,
        address oldOwner,
        address newOwner,
        address tokenRoot,
        address sendGasToAddr,
        TvmCell payload
    ) external;
}