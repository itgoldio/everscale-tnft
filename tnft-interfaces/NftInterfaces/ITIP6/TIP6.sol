pragma ton-solidity = 0.47.0;

pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import './ITIP6.sol';

abstract contract TIP6 is ITIP6 {

    mapping(bytes4 => bool) internal _supportedInterfaces;

    function supportsInterface(bytes4 interfaceID) external override view responsible returns (bool) {
        return _supportedInterfaces[interfaceID];
    }

    function calculateTIP6Selector() public pure returns (bytes4) {
        ITIP6 tip6;
        return bytes4(tvm.functionId(tip6.supportsInterface));
    }

}