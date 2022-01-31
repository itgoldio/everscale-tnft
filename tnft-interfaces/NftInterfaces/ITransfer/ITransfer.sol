pragma ton-solidity ^0.47.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import '../INftBase/INftBase.sol';

interface ITransfer {
    function transferOwnership(address addrTo) external;
}

library TransferLib {
    int constant ID = 11;        
}

abstract contract Transfer is ITransfer, NftBase {

    event OwnershipTransferred(address oldOwner, address newOwner);

    function transferOwnership(address addrTo) public override onlyOwner {
        require(msg.value >= (_indexDeployValue * 2), NftErrors.value_less_than_required);
        require(addrTo.value != 0, NftErrors.value_is_empty);

        tvm.rawReserve(msg.value, 1);

        destructIndex();

        emit ownershipTransferred(_addrOwner, addrTo);

        _addrOwner = addrTo;
        deployIndex(addrTo);
    }

}