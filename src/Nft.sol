pragma ton-solidity = 0.47.0;

pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import '../tnft-interfaces/NftInterfaces/INftBase/NftBase.sol';
import '../tnft-interfaces/NftInterfaces/IGetInfoTnft1/GetInfoTnft1.sol';
import '../tnft-interfaces/NftInterfaces/ITransfer/Transfer.sol';
import '../tnft-interfaces/NftInterfaces/IRequiredInterfaces/RequiredInterfaces.sol';
import '../tnft-interfaces/NftInterfaces/IName/Name.sol';

contract Nft is NftBase, GetInfoTnft1, Transfer, RequiredInterfaces, Name {

    constructor(
        address addrOwner, 
        TvmCell codeIndex,
        uint128 indexDeployValue
    ) public {
        optional(TvmCell) optSalt = tvm.codeSalt(tvm.code());
        require(optSalt.hasValue(), NftErrors.value_is_empty);
        (address addrRoot) = optSalt.get().toSlice().decode(address);
        require(msg.sender == addrRoot, NftErrors.sender_is_not_root);
        require(msg.value >= (_indexDeployValue * 2), NftErrors.value_less_than_required);
        tvm.accept();
        _addrRoot = addrRoot;
        _addrOwner = addrOwner;
        _codeIndex = codeIndex;
        _indexDeployValue = indexDeployValue;

        /// demo royalty, 5 percent will be received by the creator (NftRoot)
        _royalty[msg.sender] = 5;

        /// It's deprecated, it is planned to use TIP-6
        _requiredInterfaces = [RequiredInterfacesLib.ID, NftBaseLib.ID, TransferLib.ID, GetInfoTnft1Lib.ID, NameLib.ID];

        emit TokenWasMinted(addrOwner);

        deployIndex(addrOwner);
    }

}