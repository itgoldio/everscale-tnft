pragma ton-solidity >= 0.43.0;

interface IApproval {
    function setApprovalCallback(TvmCell payload) external;
    function resetApprovalCallback() external;
}