pragma ton-solidity = 0.47.0;

interface IRoyalty {
    function getRoyalty() external responsible returns (mapping(address => uint128) royalty);
}