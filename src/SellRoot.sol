pragma ton-solidity ^0.47.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import './Sell.sol';
import './errors/OffersErrors.sol';
import './interfaces/IOffersRoot.sol';
import '../tnft-interfaces/NftInterfaces/INftBaseApproval/IApproval.sol';
import '../tnft-interfaces/NftInterfaces/INftBaseApproval/INftBaseApproval.sol';

contract SellRoot is IOffersRoot, IApproval {

    uint256 _ownerPubkey;

    uint128 _marketFee;
    uint128 _deploymentFee;
    
    TvmCell _offerCode;

    event SellDeployed(
        address offerAddress, 
        address addrRoot, 
        address addrIndex, 
        address addrData, 
        uint128 price
    );

    constructor (
        TvmCell codeIndex,
        TvmCell offerCode,
        uint256 ownerPubkey,
        uint128 deploymentFee,
        uint128 marketFee
    ) public {
        tvm.accept();

        _offerCode = offerCode;
        _ownerPubkey = ownerPubkey;
        _deploymentFee = deploymentFee;
        _marketFee = marketFee;
    }
    
    function _deployOffer(
        address addrRoot,
        address addrData,
        address addrOwner,
        uint128 price
    ) private view {
        address offerAddr = new Sell {
            value: Gas.DEPLOY_OFFER_VALUE,
            code: _offerCode,
            varInit: {
                _price: price,
                _addrData: addrData,
                _marketRootAddr: address(this)
            }
        }(
            addrRoot,
            addrOwner,
            _marketFee
        );

        TvmCell empty;
        emit SellDeployed(offerAddr, addrRoot, addrData, addrOwner, price);
        IDataBaseApproval(addrData).setApproval{value: 0, flag: 128}(offerAddr, empty);
    }

    function generatePayload(
        address addrOwner,
        address addrRoot,
        uint128 price
    ) public pure responsible returns (TvmCell payload) {
        require(price > 0);

        TvmBuilder refBuilder;
        TvmBuilder payloadBuilder;

        refBuilder.store(price);
        payloadBuilder.store(addrRoot, addrOwner);
        payloadBuilder.storeRef(refBuilder);

        return {value: 0, flag: 64}(payloadBuilder.toCell());

    }

    function setApprovalCallback(TvmCell payload) public override {
        require(msg.value >= Gas.TOTAL_COSTS_FOR_DEPLOY_OFFER, 301);
        tvm.accept();
        tvm.rawReserve(msg.value, 1);

        TvmSlice slice = payload.toSlice();
        (address addrRoot, address addrOwner) = slice.decode(address, address);

        TvmSlice refSlice = slice.loadRefAsSlice();
        uint128 price = refSlice.decode(uint128);

        require(price > 0, 303);

        _deployOffer(
            addrRoot,
            msg.sender,
            addrOwner,
            price
        );
    }

    function resetApprovalCallback() public override {
        require(true, 404, "Method is not supported!");
    }

    function getOfferAddress(
        address addrData,
        uint128 price
    ) public view returns (address offerAddress) {
        TvmCell stateInit = tvm.buildStateInit({
            contr: Sell, 
            code: _offerCode,
            varInit: {
                _price: price,
                _addrData: addrData,
                _marketRootAddr: address(this)
            }
        });

        offerAddress = address(tvm.hash(stateInit));
    }

    function changeDeploymentFee(uint128 deploymentFee) external override onlyOwner {
        tvm.accept();
        _deploymentFee = deploymentFee;
    }

    function changeMarketFee(uint128 marketFee) external override onlyOwner {
        tvm.accept();
        _marketFee = marketFee;
    }

    function setOfferCode(TvmCell offerCode) external override onlyOwner {
        tvm.accept();
        _offerCode = offerCode;
    }
    
    function withdraw(address dest, uint128 value) external pure onlyOwner {
        tvm.accept();
        dest.transfer(value, true);
    }

    modifier onlyOwner {
        require(msg.pubkey() == _ownerPubkey, OffersErrors.message_sender_is_not_my_owner);
        _;
    }

}