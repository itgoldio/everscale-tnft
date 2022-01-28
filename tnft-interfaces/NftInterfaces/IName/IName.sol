pragma ton-solidity = 0.47.0;

interface IName {
    function getName() external returns (string dataName);
    function getNameResponsible() external responsible returns (string dataName);
}

library NameLib {
    int constant ID = 2;        
}

abstract contract Name is IName {

    string _dataName;

    function getName() public override returns (string dataName) {
        return _dataName;
    }   

    function getNameResponsible() public override responsible returns (string dataName) {
        return {value: 0, flag: 64}(_dataName);
    }
}