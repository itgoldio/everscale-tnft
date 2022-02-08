pragma ton-solidity = 0.47.0;

pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import '../tnft-interfaces/NftInterfaces/INftBase/NftBase.sol';
import '../tnft-interfaces/NftInterfaces/IName/Name.sol';
import '../tnft-interfaces/NftInterfaces/ITIP6/TIP6.sol';
import '../tnft-interfaces/NftInterfaces/INftBaseApproval/NftBaseApproval.sol';
import '../tnft-interfaces/NftInterfaces/IRoyalty/Royalty.sol';
import '../tnft-interfaces/NftInterfaces/IAuthor/Author.sol';


contract Nft is NftBase, Name, TIP6, NftBaseApproval, Royalty, Author {

    constructor(
        address addrOwner, 
        TvmCell codeIndex,
        uint128 indexDeployValue, 
        string dataName, 
        address authorAddr,
        uint128 authorRoyalty
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

        _authorAddr = authorAddr;
        _royalty[_authorAddr] = authorRoyalty;

        _supportedInterfaces[ 
            bytes4(
            tvm.functionId(INftBase.setIndexDeployValue) ^ 
            tvm.functionId(INftBase.transferOwnership) ^
            tvm.functionId(INftBase.getIndexDeployValue) ^
            tvm.functionId(INftBase.getOwner)
            )
        ] = true;

        _supportedInterfaces[
            bytes4(
                tvm.functionId(INftBaseApproval.setApproval) ^
                tvm.functionId(INftBaseApproval.returnOwnership) ^                 
                tvm.functionId(INftBaseApproval.getApproval)
            )
        ] = true;

        _supportedInterfaces[ bytes4(tvm.functionId(IName.getName)) ] = true;
        _supportedInterfaces[ bytes4(tvm.functionId(ITIP6.supportsInterface)) ] = true;
        _supportedInterfaces[ bytes4(tvm.functionId(IAuthor.getAuthor)) ] = true;
        _supportedInterfaces[ bytes4(tvm.functionId(IRoyalty.getRoyalty)) ] = true;

        emit TokenWasMinted(addrOwner);

        _deployIndex();
    }

    modifier onlyOwner override(NftBase, NftBaseApproval) {
        require((msg.sender == _addrOwner && !_approval.hasValue()) || (_approval.hasValue() && msg.sender == _approval.get()));
        _;
    }

}