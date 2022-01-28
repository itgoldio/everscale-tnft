pragma ton-solidity = 0.47.0;

import '../INftBase/INftBase.sol';

interface IBurnByOwner {
    function burnByOwner(address dest) external;
}

library BurnByOwnerLib {
    int constant ID = 9;        
}

abstract contract BurnByOwner is IBurnByOwner, NftBase {

    function burnByOwner(address dest) external override onlyOwner {
        tvm.accept();
        selfdestruct(dest);
    }

}