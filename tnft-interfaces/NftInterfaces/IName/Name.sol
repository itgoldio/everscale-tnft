pragma ton-solidity = 0.47.0;

pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import './IName.sol';

abstract contract Name is IName {

    string _dataName;

    function getName() public override responsible returns (string dataName) {
        return {value: 0, flag: 64}(_dataName);
    }

}