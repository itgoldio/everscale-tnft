pragma ton-solidity >=0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import './interfaces/IDataBase.sol';
import './interfaces/IRequiredInterfaces.sol';
import './interfaces/IGetInfo.sol';
import './interfaces/ITransfer.sol';

contract Data is DataBase, RequiredInterfaces, Transfer, GetInfo {

    constructor(
        address addrOwner, 
        TvmCell codeIndex,
        uint128 indexDeployValue
    ) public {
        optional(TvmCell) optSalt = tvm.codeSalt(tvm.code());
        require(optSalt.hasValue(), DataErrors.value_is_empty);
        (address addrRoot) = optSalt.get().toSlice().decode(address);
        require(msg.sender == addrRoot, DataErrors.sender_is_not_root);
        require(msg.value >= (_indexDeployValue * 2), DataErrors.value_less_than_required);
        tvm.accept();
        _addrRoot = addrRoot;
        _addrOwner = addrOwner;
        _codeIndex = codeIndex;
        _indexDeployValue = indexDeployValue;

        /// simple royalty, 5 percent will be received by the creator (NftRoot)
        _royalty[msg.sender] = 5;

        _requiredInterfaces = [RequiredInterfacesLib.ID, DataBaseLib.ID, TransferLib.ID, GetInfoLib.ID];

        emit tokenWasMinted(addrOwner);

        deployIndex(addrOwner);
    }

}