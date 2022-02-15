pragma ton-solidity >=0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import './interfaces/IIndex.sol';

contract Index is IIndex {
    address _addrRoot;
    address _addrOwner;
    address static _addrNft;

    constructor(
        address root, 
        address sendGasToAddr, 
        uint128 remainOnIndex
    ) public {
        optional(TvmCell) optSalt = tvm.codeSalt(tvm.code());
        require(optSalt.hasValue(), 101);
        (address addrRoot, address addrOwner) = optSalt
            .get()
            .toSlice()
            .decode(address, address);
        require(msg.sender == _addrNft);
        tvm.accept();
        tvm.rawReserve(address(this).balance - remainOnIndex, 1);

        _addrRoot = addrRoot;
        _addrOwner = addrOwner;
        if(addrRoot == address(0)) {
            _addrRoot = root;
        }

        sendGasToAddr = sendGasToAddr.value != 0 ? sendGasToAddr : msg.sender;
        sendGasToAddr.transfer({value: 0, flag: 128});
    }

    function getInfo() public responsible view override returns (
        address addrRoot,
        address addrOwner,
        address addrNft
    ) {
        return {value: 0, flag: 64}(_addrRoot, _addrOwner, _addrNft);
    }

    function destruct(address sendGasToAddr) public override {
        require(msg.sender == _addrNft);
        
        if (sendGasToAddr.value != 0) {
            selfdestruct(sendGasToAddr);
        } else {
            selfdestruct(_addrNft);
        }
    }
}