pragma ton-solidity = 0.47.0;

pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;


interface INftBase {
    function setIndexDeployValue(uint128 indexDeployValue) external;
    function getSummaryRoyalty() external responsible returns(uint128 royaltyValue);
    function getRoyalty() external responsible returns(mapping(address => uint128) royalty);
    function getIndexDeployValue() external responsible returns(uint128);
    function getOwner() external responsible returns(address addrOwner);
}