pragma ton-solidity = 0.47.0;

import './IRequiredInterfaces.sol';

library RequiredInterfacesLib {
    int constant ID = 1;        
}

abstract contract RequiredInterfaces is IRequiredInterfaces {

    int[] _requiredInterfaces;

    function getRequiredInterfaces() external override returns(int[] requiredInterfaces) {
        return _requiredInterfaces;
    }

    function getRequiredInterfacesResponsible() external override responsible returns(int[] requiredInterfaces) {
        return {value: 0, flag: 64}(_requiredInterfaces);
    }
}