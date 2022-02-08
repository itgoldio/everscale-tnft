pragma ton-solidity ^0.47.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;


interface INftBaseApproval {
    function setApproval(address approval, TvmCell payload) external;
    function returnOwnership() external;
    function getApproval() external returns(address approval);
}
