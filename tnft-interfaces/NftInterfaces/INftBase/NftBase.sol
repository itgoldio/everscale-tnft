pragma ton-solidity = 0.58.1;

pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import '../../../src/errors/NftErrors.sol';
import './INftBase.sol';
import './IManager.sol';
import './ITokenTransferCallback.sol';


abstract contract NftBase is INftBase {

    uint256 static _id;

    address _addrRoot;
    address _addrOwner;
    address _addrManager = _addrOwner;
    string _json;
    
    event TokenWasMinted(address owner);
    event OwnershipTransferred(address oldOwner, address newOwner);

    /// @param sendGasToAddr can be empty. If sendGasToAddr is not empty - remaining gas will be returned to the specified address, else gas will be transferred to sender
    /// @param addrTo can't be empty. After executing the method, the account with this address will become the owner
    /// @param callbacks for receiving callback
    function transferOwnership(
        address sendGasToAddr, 
        address addrTo, 
        mapping(address => CallbackParams) callbacks
    ) public override onlyManager {
        require(addrTo.value != 0, NftErrors.value_is_empty);
        tvm.rawReserve(msg.value, 1);

        address addrOwner = _addrOwner;
        sendGasToAddr = sendGasToAddr.value != 0 ? sendGasToAddr : msg.sender;

        _transfer(addrTo);
        emit OwnershipTransferred(addrOwner, addrTo);

        optional(TvmCell) callbackToGasOwner;
        for ((address dest, CallbackParams p) : callbacks) {
            if (dest.value != 0) {
                if (sendGasToAddr != dest) {
                    ITokenTransferCallback(dest).tokenTransferCallback{
                        value: p.value,
                        flag: 0,
                        bounce: false
                    }(_id, addrOwner, addrTo, _addrRoot, sendGasToAddr, p.payload);
                } else {
                    callbackToGasOwner.set(p.payload);
                }
            }
        }

        if (sendGasToAddr.value != 0) {
            if (callbackToGasOwner.hasValue()) {
                ITokenTransferCallback(sendGasToAddr).tokenTransferCallback{
                    value: 0,
                    flag: 128,
                    bounce: false
                }(_id, addrOwner, addrTo, _addrRoot, sendGasToAddr, callbackToGasOwner.get());
            } else {
                sendGasToAddr.transfer({
                    value: 0,
                    flag: 128,
                    bounce: false
                });
            }
        }

    }

    function _transfer(
        address to
    ) internal {
        require(to.value != 0, NftErrors.value_is_empty);

        _addrOwner = to;
    }

    function setManager(address manager, TvmCell payload) public override onlyManager {
        require(msg.value != 0);
        tvm.accept();
        tvm.rawReserve(msg.value, 1);
    
        _addrManager = manager;
        IManager(manager).setManagerCallback{value: 0, flag: 128}(payload);
    }

    function returnOwnership() public override onlyManager {
        require(_addrManager != _addrOwner);
        tvm.accept();
        tvm.rawReserve(msg.value, 1);

        address manager = _addrManager;
        _addrManager = _addrOwner;

        IManager(manager).resetManagerCallback{value: 0, flag: 128}();
    }

    function getInfo() external override responsible returns(
        uint256 id,
        address addrOwner,
        address addrCollection,
        address addrManager
    ) {
        return {value: 0, flag: 64}( _id, _addrOwner, _addrRoot, _addrManager );
    }

    function getJSONInfo() external override responsible returns(string json) {
        return {value: 0, flag: 64}(_json);
    }

    modifier onlyManager virtual {
        require(msg.sender == _addrOwner, NftErrors.sender_is_not_owner);
        _;
    }

}