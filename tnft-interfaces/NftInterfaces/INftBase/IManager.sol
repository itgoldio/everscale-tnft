pragma ton-solidity >= 0.43.0;

interface IManager {
    function setManagerCallback(TvmCell payload) external;
    function resetManagerCallback() external;
}