pragma ton-solidity = 0.47.0;

pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;


interface INftBase {
    function setIndexDeployValue(uint128 indexDeployValue) external;
    function transferOwnership(
        address callbackAddr, 
        address sendGasToAddr, 
        address addrTo, 
        TvmCell payload
    ) external;
    function getIndexDeployValue() external responsible returns(uint128);
    function getOwner() external responsible returns(address addrOwner);
}