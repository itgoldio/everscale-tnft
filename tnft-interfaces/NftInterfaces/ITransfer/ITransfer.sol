pragma ton-solidity = 0.47.0;

pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

interface ITransfer {
    function transferOwnership(address addrTo) external;
}