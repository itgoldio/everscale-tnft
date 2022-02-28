pragma ton-solidity = 0.47.0;

pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import './structures/ICallbackParamsStructure.sol';


interface INftBase is ICallbackParamsStructure {
    
    function setIndexDestroyValue(uint128 indexDestroyValue) external;
    function setIndexDeployValue(uint128 indexDeployValue) external;
    function transferOwnership(
        address sendGasToAddr, 
        address addrTo, 
        mapping(address => CallbackParams) callbacks
    ) external;
    function getIndexDeployValue() external responsible returns(uint128);
    function getIndexDestroyValue() external responsible returns(uint128);
    function setManager(address manager, TvmCell payload) external;
    function returnOwnership() external;
    function getInfo() external responsible returns(
        uint256 id,
        address addrOwner,
        address addrCollection,
        address addrManager
    );
    function getJsonInfo() external responsible returns(string json);

}
