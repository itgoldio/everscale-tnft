pragma ton-solidity ^0.47.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import './interfaces/IOffer.sol';
import '../tnft-interfaces/NftBase/INftBase.sol';
import '../tnft-interfaces/INftBaseApproval/Approval.sol';
import '../tnft-interfaces/INftBaseApproval/INftBaseApproval.sol';
import './errors/OffersErrors.sol';
import './libraries/Gas.sol';

contract Sell is IOffer, IApproval {

    uint128 static _price;
    address static _addrData;
    address static _marketRootAddr;

    bool public _paused = true;

    address _tokenRootAddr;
    address _addrOwner;

    uint128 _marketFee;

    event sellConfirmed(address dataAddr, address buyerAddr);

    constructor(
        address tokenRootAddr,
        address addrOwner,
        uint128 marketFeeValue
    ) public {
        require(msg.sender == _marketRootAddr);
        tvm.accept();

        _tokenRootAddr = tokenRootAddr;
        _addrOwner = addrOwner;
        _marketFee = marketFeeValue;
    }

    function buyToken() external isActive {
        require(msg.value >= _price, OffersErrors.not_enough_value_to_buy);
        require(msg.sender != _addrOwner, OffersErrors.buyer_is_my_owner);
        tvm.accept();

        _paused = true;
        TvmCell empty;
        INftBase(_addrData).transferOwnership{value: _price, bounce: true}(address(this), address(0), msg.sender, empty);
    
    }

    transferOwnership(
        address callbackAddr, 
        address sendGasToAddr, 
        address addrTo, 
        TvmCell payload

    receive() external {
        require(msg.value >= _price, OffersErrors.not_enough_value_to_buy);
        require(msg.sender != _addrOwner, OffersErrors.buyer_is_my_owner);
        require(!_paused);
        tvm.accept();
   
        _paused = true;
        TvmCell empty;
        INftBase(_addrData).transferOwnership{value: _price, bounce: true}(address(this), address(0), msg.sender, empty);
    
    }

    function cancelOrder() external isActive {
        require(msg.value > 0.15 ton);
        require(msg.sender == _addrOwner);
        tvm.accept();
        tvm.rawReserve(msg.value, 1);

        _paused = true;
        IDataBaseApproval(_addrData).returnOwnership{value: 0, flag: 128, bounce: true}();
    }

    function setApprovalCallback(TvmCell payload) external onlyData override {
        tvm.accept();
        tvm.rawReserve(msg.value, 1);

        _paused = false;
        _addrOwner.transfer({value: 0, flag: 128, bounce: true});

        payload; // disable warnings
    }

    function tokenTransferCallback(
        address oldOwner,
        address newOwner,
        address tokenRoot,
        address sendGasToAddr,
        TvmCell payload
    ) external onlyData override {
        
        emit sellConfirmed(_addrData, newOwner);
        destruct(_marketRootAddr);
    
    }

    function resetApprovalCallback() external onlyData override {
        destruct(_addrOwner);
    }

    function destruct(address destAddr) private {
        selfdestruct(destAddr);
    }

    function getOfferInfo() public view returns(
        uint128 price,
        address addrData,
        address marketRootAddr,
        address tokenRootAddr,
        address addrOwner,
        uint128 marketFee
    ){
        return (
            _price,
            _addrData,
            _marketRootAddr,
            _tokenRootAddr,
            _addrOwner,
            _marketFee
        );
    }

    modifier isActive {
        require(!_paused);
        _;
    }

    modifier onlyData {
        require(msg.sender == _addrData);
        _;
    }

}