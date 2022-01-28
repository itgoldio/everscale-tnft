pragma ton-solidity >=0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import '../tnft-interfaces/NftInterfaces/INftBase/INftBase.sol';
import '../tnft-interfaces/NftInterfaces/IGetInfo/IGetInfo.sol';
import '../tnft-interfaces/NftInterfaces/INftBaseApproval/INftBaseApproval.sol';

contract Nft is NftBase, GetInfo, NftBaseApproval {

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

        /// simple royalty, 5 percent will be received by the creator (NftRoot)
        _royalty[msg.sender] = 5;

        // _requiredInterfaces = [RequiredInterfacesLib.ID, NftBaseLib.ID, TransferLib.ID, GetInfoLib.ID];

        emit tokenWasMinted(addrOwner);

        deployIndex(addrOwner);
    }

    modifier onlyOwner override(NftBase, NftBaseApproval) {
        require((msg.sender == _addrOwner && !_approval.hasValue()) || (_approval.hasValue() && msg.sender == _approval.get()));
        _;
    }

}