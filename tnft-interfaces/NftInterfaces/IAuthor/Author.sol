pragma ton-solidity = 0.47.0;

pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import './IAuthor.sol';

abstract contract Author is IAuthor {

    address _authorAddr;

    function getAuthor() public override responsible returns (address authorAddr) {
        return {value: 0, flag: 64}(_authorAddr);
    }

}