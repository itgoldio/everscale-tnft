pragma ton-solidity >= 0.43.0;

interface IOffer {
    function transferSuccessCallback(address newOwner) external;
    function transferFailedCallback() external;
}
