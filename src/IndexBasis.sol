pragma ton-solidity >=0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;

contract IndexBasis {
    address static _addrRoot;
    uint256 static _codeHashNft;

    modifier onlyRoot() {
        require(msg.sender == _addrRoot, 100);
        tvm.accept();
        _;
    }

    constructor() public onlyRoot {}

    function getInfo() public view returns (address addrRoot, uint256 codeHashNft) {
        addrRoot = _addrRoot;
        codeHashNft = _codeHashNft;
    }

    function destruct() public onlyRoot {
        selfdestruct(_addrRoot);
    }
}