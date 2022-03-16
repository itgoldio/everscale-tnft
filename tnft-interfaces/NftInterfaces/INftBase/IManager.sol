pragma ton-solidity = 0.58.1;

interface IManager {
    function setManagerCallback(TvmCell payload) external;
    function resetManagerCallback() external;
}