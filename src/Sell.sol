pragma ton-solidity ^0.47.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import '../tnft-interfaces/NftInterfaces/INftBase/ITokenTransferCallback.sol';
import '../tnft-interfaces/NftInterfaces/INftBase/NftBase.sol';
import '../tnft-interfaces/NftInterfaces/INftBaseApproval/IApproval.sol';
import '../tnft-interfaces/NftInterfaces/INftBaseApproval/INftBaseApproval.sol';
import '../tnft-interfaces/NftInterfaces/IRoyalty/IRoyalty.sol';
import './errors/OffersErrors.sol';
import './libraries/Gas.sol';

contract Sell is ITokenTransferCallback, IApproval {

    uint constant REQUIRED_STEPS = 2;

    uint128 static _price;
    address static _addrNft;
    address static _marketRootAddr;

    bool public _paused = true;
    uint public _steps = 0;

    address _tokenRootAddr;
    address _addrOwner;

    mapping(address => uint128) _royalty;

    event sellConfirmed(address nftAddr, address buyerAddr);

    constructor(
        address tokenRootAddr,
        address addrOwner,
        uint128 marketFeeValue
    ) public {
        require(msg.sender == _marketRootAddr);
        require(_price > marketFeeValue);
        tvm.accept();

        _tokenRootAddr = tokenRootAddr;
        _addrOwner = addrOwner;
        uint128 feeValue = math.muldiv(marketFeeValue, 100, _price);
        _royalty[_marketRootAddr] = feeValue;

        getRoyalty();
    }

    function _checkSteps() private {
        if (_steps == REQUIRED_STEPS) {
            _paused = false;
        }
    }

    function _distribute() private {
        for ((address addr, uint128 value) : _royalty) {
            uint128 feeValue = math.muldiv(_price, value, 100);
            addr.transfer({value: feeValue, bounce: true});
        }

        _addrOwner.transfer({value: 0, flag: 128, bounce: true});
    }

    function getRoyalty() private {
        IRoyalty(_addrNft).getRoyalty{callback: Sell.onGetRoyalty}();
    }

    function onGetRoyalty(mapping(address => uint128) royalty) external onlyNft {
        tvm.accept();
        tvm.rawReserve(msg.value, 1);

        _royalty = royalty;
        _steps++;
        _checkSteps();
        _addrOwner.transfer({value: 0, flag: 128, bounce: true});
    }

    function buyToken() external isActive {
        require(msg.value >= _price, OffersErrors.not_enough_value_to_buy);
        require(msg.sender != _addrOwner, OffersErrors.buyer_is_my_owner);
        tvm.accept();

        _paused = true;
        TvmCell empty;
        INftBase(_addrNft).transferOwnership{value: _price, bounce: true}(address(this), address(0), msg.sender, empty);
    
    }

    receive() external {
        require(msg.value >= _price, OffersErrors.not_enough_value_to_buy);
        require(msg.sender != _addrOwner, OffersErrors.buyer_is_my_owner);
        require(!_paused);
        tvm.accept();
   
        _paused = true;
        TvmCell empty;
        INftBase(_addrNft).transferOwnership{value: _price, bounce: true}(address(this), address(0), msg.sender, empty);
    
    }

    function cancelOrder() external isActive {
        require(msg.value > 0.15 ton);
        require(msg.sender == _addrOwner);
        tvm.accept();
        tvm.rawReserve(msg.value, 1);

        _paused = true;
        INftBaseApproval(_addrNft).returnOwnership{value: 0, flag: 128, bounce: true}();
    }

    function setApprovalCallback(TvmCell payload) external onlyNft override {
        tvm.accept();
        tvm.rawReserve(msg.value, 1);

        _steps++;
        _checkSteps();
        _addrOwner.transfer({value: 0, flag: 128, bounce: true});

        payload; // disable warnings
    }

    function tokenTransferCallback(
        address oldOwner,
        address newOwner,
        address tokenRoot,
        address sendGasToAddr,
        TvmCell payload
    ) external onlyNft override {
        
        emit sellConfirmed(_addrNft, newOwner);
        _distribute();
        destruct(_marketRootAddr);
    
    }

    function resetApprovalCallback() external onlyNft override {
        destruct(_addrOwner);
    }

    function destruct(address destAddr) private {
        selfdestruct(destAddr);
    }

    function getOfferInfo() public view returns(
        uint128 price,
        address addrNft,
        address marketRootAddr,
        address tokenRootAddr,
        address addrOwner
    ){
        return (
            _price,
            _addrNft,
            _marketRootAddr,
            _tokenRootAddr,
            _addrOwner
        );
    }

    modifier isActive {
        require(!_paused);
        _;
    }

    modifier onlyNft {
        require(msg.sender == _addrNft);
        _;
    }

}