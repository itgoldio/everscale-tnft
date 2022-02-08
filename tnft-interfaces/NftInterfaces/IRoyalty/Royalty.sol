pragma ton-solidity = 0.47.0;

pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import './IRoyalty.sol';

abstract contract Royalty is IRoyalty {

    mapping(address => uint128) _royalty;

    function getRoyalty() external override responsible returns (mapping(address => uint128) royalty){
        return {value: 0, flag: 64}(_royalty);
    }

}