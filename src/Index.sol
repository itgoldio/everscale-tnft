pragma ton-solidity >=0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import './interfaces/IIndex.sol';

contract Index is IIndex {
    address _addrRoot;
    address _addrOwner;
    address static _addrNft;

    constructor(address root) public {
        optional(TvmCell) optSalt = tvm.codeSalt(tvm.code());
        require(optSalt.hasValue(), 101);
        (address addrRoot, address addrOwner) = optSalt
            .get()
            .toSlice()
            .decode(address, address);
        require(msg.sender == _addrNft);
        tvm.accept();
        _addrRoot = addrRoot;
        _addrOwner = addrOwner;
        if(addrRoot == address(0)) {
            _addrRoot = root;
        }
    }

    function getInfo() public view override returns (
        address addrRoot,
        address addrOwner,
        address addrNft
    ) {
        addrRoot = _addrRoot;
        addrOwner = _addrOwner;
        addrNft = _addrNft;
    }

    function destruct() public override {
        require(msg.sender == _addrNft);
        selfdestruct(_addrNft);
    }
}