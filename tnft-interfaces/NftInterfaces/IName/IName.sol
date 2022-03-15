pragma ton-solidity = 0.58.1;

interface IName {
    function getName() external responsible returns (string dataName);
}