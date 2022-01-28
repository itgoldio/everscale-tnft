pragma ton-solidity >=0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import '../../INftBase/INftBase.sol';
import '../../IRequiredInterfaces/IRequiredInterfaces.sol';
import '../../IGetInfo/IGetInfo.sol';
import '../../ITransfer/ITransfer.sol';

contract Data is NftBase, RequiredInterfaces, Transfer, GetInfo {

    constructor(
        address addrOwner, 
        TvmCell codeIndex
    ) public {
        optional(TvmCell) optSalt = tvm.codeSalt(tvm.code());
        require(optSalt.hasValue(), 101);
        (address addrRoot) = optSalt.get().toSlice().decode(address);
        require(msg.sender == addrRoot);
        require(msg.value >= Constants.MIN_FOR_DEPLOY_INDEXES);
        tvm.accept();
        _addrRoot = addrRoot;
        _addrOwner = addrOwner;
        _codeIndex = codeIndex;

        _requiredInterfaces = [RequiredInterfacesLib.ID];

        /// simple royalty, 5 percent will be received by the creator (NftRoot)
        _royalty[msg.sender] = 5;

        _requiredInterfaces = [RequiredInterfacesLib.ID, NftBaseLib.ID, TransferLib.ID, GetInfoLib.ID];

        emit tokenWasMinted(addrOwner);

        deployIndex(addrOwner);
    }

}