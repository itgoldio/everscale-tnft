pragma ton-solidity ^0.47.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import '../INftBaseApproval/INftBaseApproval.sol';
import './interfaces/IOffer.sol';

interface IPaidTransfer {
    function paidTransfer(address newOwner, uint128 marketFeeValue) external;
}

abstract contract PaidTransfer is IPaidTransfer, NftBaseApproval {

    event tokenWasPurchased(address oldOwner, address newOwner, uint128 price);

    function paidTransfer(address newOwner, uint128 marketFeeValue) external onlyApproval override {
        require(msg.value != 0);
        require(newOwner != address(0));
        tvm.accept();
        tvm.rawReserve(msg.value, 1);

        if (
            msg.value < getSummaryRoyalty() + marketFeeValue ||
            newOwner == address(0)
        ) {
            IOffer(msg.sender).transferFailedCallback{value: 0, flag: 128, bounce: true}();
        }

        for ((address key, uint128 value) : _royalty) { // iteration over mapping 
            key.transfer({value: value, bounce: true});
        }

        destructIndex();
        emit tokenWasPurchased(_addrOwner, newOwner, msg.value);

        _addrOwner = newOwner;
        deployIndex(newOwner);

        IOffer(msg.sender).transferSuccessCallback{value: marketFeeValue, bounce: true}(newOwner);

        _addrOwner.transfer({value: 0, flag: 128});
    }

}