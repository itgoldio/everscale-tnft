pragma ton-solidity = 0.47.0;

interface IAuthor {
    function getAuthor() external responsible returns (address authorAddr);
}