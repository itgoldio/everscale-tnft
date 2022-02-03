pragma ton-solidity = 0.47.0;

pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import '../tnft-interfaces/NftInterfaces/INftBase/NftBase.sol';
import '../tnft-interfaces/NftInterfaces/IName/Name.sol';
import '../tnft-interfaces/NftInterfaces/ITIP6/TIP6.sol';

contract Nft is NftBase, Name, TIP6 {

    constructor(
        address addrOwner, 
        TvmCell codeIndex,
        uint128 indexDeployValue, 
        string dataName
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
        _dataName = dataName;

        _supportedInterfaces[ calculateNftBaseSelector() ] = true;
        _supportedInterfaces[ calculateNameSelector() ] = true;
        _supportedInterfaces[ calculateTIP6Selector() ] = true;

        emit TokenWasMinted(addrOwner);

        _deployIndex();
    }

}