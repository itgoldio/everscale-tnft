pragma ton-solidity = 0.47.0;

pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import './structures/ICallbackParamsStructure.sol';


interface INftBase is ICallbackParamsStructure {
    
    function transferOwnership(
        address sendGasToAddr, 
        address addrTo, 
        mapping(address => CallbackParams) callbacks
    ) external;
    function setManager(address manager, TvmCell payload) external;
    function returnOwnership() external;
    function getInfo() external responsible returns(
        uint256 id,
        address addrOwner,
        address addrCollection,
        address addrManager
    );
    function getJSONInfo() external responsible returns(string json);

}
