pragma ton-solidity ^0.47.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import '../INftBase/NftBase.sol';
import './IApproval.sol';
import './INftBaseApproval.sol';

abstract contract NftBaseApproval is INftBaseApproval, NftBase {

    optional(address) _approval;

    function setApproval(address approval, TvmCell payload) public override onlyOwner {
        require(msg.value != 0);
        tvm.accept();
        tvm.rawReserve(msg.value, 1);
    
        _approval = approval;
        IApproval(approval).setApprovalCallback{value: 0, flag: 128}(payload);
    }

    function returnOwnership() public override onlyApproval {
        tvm.accept();
        tvm.rawReserve(msg.value, 1);

        address approval = _approval.get();
        _approval.reset();

        IApproval(approval).resetApprovalCallback{value: 0, flag: 128}();
    }

    function getApproval() public override returns(address approval) {
        approval = _approval.hasValue() ? _approval.get() : address(0); 
    }

    modifier onlyApproval {
        require(msg.sender == _approval && _approval.hasValue());
        _;
    }

    modifier onlyOwner virtual override {
        require((msg.sender == _addrOwner && !_approval.hasValue()) || (_approval.hasValue() && msg.sender == _approval.get()));
        _;
    }

}