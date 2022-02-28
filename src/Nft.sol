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
        string json,
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
        _json = json;
        _dataName = dataName;

        _supportedInterfaces[ 
            bytes4(
            tvm.functionId(INftBase.setIndexDestroyValue) ^
            tvm.functionId(INftBase.setIndexDeployValue) ^ 
            tvm.functionId(INftBase.transferOwnership) ^
            tvm.functionId(INftBase.getIndexDeployValue) ^
            tvm.functionId(INftBase.getIndexDestroyValue) ^
            tvm.functionId(INftBase.setManager) ^ 
            tvm.functionId(INftBase.returnOwnership) ^
            tvm.functionId(INftBase.getInfo)
            )
        ] = true;

        _supportedInterfaces[ bytes4(tvm.functionId(IName.getName)) ] = true;
        _supportedInterfaces[ bytes4(tvm.functionId(ITIP6.supportsInterface)) ] = true;

        emit TokenWasMinted(addrOwner);

        _deployIndex(addrOwner);
    }

}