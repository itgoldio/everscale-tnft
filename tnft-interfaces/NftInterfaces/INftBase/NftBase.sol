pragma ton-solidity = 0.47.0;

pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import '../../../src/resolvers/IndexResolver.sol';
import '../../../src/errors/NftErrors.sol';
import './INftBase.sol';
import './ITokenTransferCallback.sol';


abstract contract NftBase is INftBase, IndexResolver {

    uint256 static _id;

    address _addrRoot;
    address _addrOwner;

    uint128 _indexDeployValue;
    
    event TokenWasMinted(address owner);
    event OwnershipTransferred(address oldOwner, address newOwner);

    /// @param callbackAddr can be empty. If callbackAddr is not empty - the transfer function will be called for an account with this address (callbackAddr)
    /// @param sendGasToAddr can be empty. If sendGasToAddr is not empty - remaining gas will be returned to the specified address, else gas will be transferred to sender
    /// @param addrTo can't be empty. After executing the method, the account with this address will become the owner
    /// @param payload can be empty. It will be sent to the callback address if callbackAddr is not empty
    function transferOwnership(
        address callbackAddr, 
        address sendGasToAddr, 
        address addrTo, 
        TvmCell payload
    ) public override onlyOwner {
        require(msg.value >= (_indexDeployValue * 2), NftErrors.value_less_than_required);
        require(addrTo.value != 0, NftErrors.value_is_empty);
        tvm.rawReserve(msg.value, 1);

        address addrOwner = _addrOwner;
        sendGasToAddr = sendGasToAddr.value != 0 ? sendGasToAddr : msg.sender;

        _transfer(addrTo, sendGasToAddr);
        emit OwnershipTransferred(addrOwner, addrTo);

        if (callbackAddr.value != 0) {
            ITokenTransferCallback(callbackAddr).tokenTransferCallback{value: 0, flag: 128}(
                addrOwner, 
                addrTo,
                _addrRoot, 
                sendGasToAddr,
                payload
            );
        } else {
            sendGasToAddr.transfer({value: 0, flag: 128});
        }

    }

    function _transfer(
        address to,
        address sendGasToAddr
    ) internal {
        require(to.value != 0, NftErrors.value_is_empty);

        _destructIndex(sendGasToAddr);
        _addrOwner = to;
        _deployIndex();
    }

    function _deployIndex() internal view {
        TvmCell codeIndexOwner = _buildIndexCode(_addrRoot, _addrOwner);
        TvmCell stateIndexOwner = _buildIndexState(codeIndexOwner, address(this));
        new Index{stateInit: stateIndexOwner, value: _indexDeployValue}(_addrRoot);

        TvmCell codeIndexOwnerRoot = _buildIndexCode(address(0), _addrOwner);
        TvmCell stateIndexOwnerRoot = _buildIndexState(codeIndexOwnerRoot, address(this));
        new Index{stateInit: stateIndexOwnerRoot, value: _indexDeployValue}(_addrRoot);
    }

    function _destructIndex(address sendGasToAddr) internal view {
        address oldIndexOwner = resolveIndex(address(0), address(this), _addrOwner);
        IIndex(oldIndexOwner).destruct(sendGasToAddr);
        address oldIndexOwnerRoot = resolveIndex(_addrRoot, address(this), _addrOwner);
        IIndex(oldIndexOwnerRoot).destruct(sendGasToAddr);
    }

    function setIndexDeployValue(uint128 indexDeployValue) public override onlyOwner {
        tvm.rawReserve(msg.value, 1);
        _indexDeployValue = indexDeployValue;
        msg.sender.transfer({value: 0, flag: 128});
    }

    function getIndexDeployValue() public responsible override returns(uint128) {
        return {value: 0, flag: 64} _indexDeployValue;
    }

    function getOwner() public responsible override returns(address addrOwner) {
        return {value: 0, flag: 64} _addrOwner;
    }

    function calculateNftBaseSelector() public pure returns(bytes4) {
        INftBase nftBase;
        return bytes4(
            tvm.functionId(nftBase.setIndexDeployValue) ^ 
            tvm.functionId(nftBase.transferOwnership) ^
            tvm.functionId(nftBase.getIndexDeployValue) ^
            tvm.functionId(nftBase.getOwner)
        );
    }

    modifier onlyOwner virtual {
        require(msg.sender == _addrOwner, NftErrors.sender_is_not_owner);
        _;
    }

}