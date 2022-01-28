pragma ton-solidity >=0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import '../../../vendoring/resolvers/IndexResolver.sol';
import '../../../vendoring/interfaces/IData.sol';
import '../../../vendoring/libraries/Constants.sol';

import '../../IRequiredInterfaces/IRequiredInterfaces.sol';

contract Data is IData, IndexResolver, RequiredInterfaces {
    address _addrRoot;
    address _addrOwner;

    uint256 static _id;

    event tokenWasMinted(address owner);
    event ownershipTransferred(address oldOwner, address newOwner);

    constructor(
        address addrOwner, 
        TvmCell codeIndex
    ) public {
        optional(TvmCell) optSalt = tvm.codeSalt(tvm.code());
        require(optSalt.hasValue(), 101);
        (address addrRoot) = optSalt.get().toSlice().decode(address);
        require(msg.sender == addrRoot);
        require(msg.value >= Constants.MIN_FOR_DEPLOY_INDEXES);
        tvm.accept();
        _addrRoot = addrRoot;
        _addrOwner = addrOwner;
        _codeIndex = codeIndex;

        _requiredInterfaces = [RequiredInterfacesLib.ID];

        emit tokenWasMinted(addrOwner);

        deployIndex(addrOwner);
    }

    function transferOwnership(address addrTo) public override {
        require(msg.sender == _addrOwner);
        require(msg.value >= Constants.MIN_FOR_DEPLOY_INDEXES);
        require(addrTo != address(0));

        address oldIndexOwner = resolveIndex(_addrRoot, address(this), _addrOwner);
        IIndex(oldIndexOwner).destruct();
        address oldIndexOwnerRoot = resolveIndex(address(0), address(this), _addrOwner);
        IIndex(oldIndexOwnerRoot).destruct();

        emit ownershipTransferred(_addrOwner, addrTo);

        _addrOwner = addrTo;
        deployIndex(addrTo);
    }

    function deployIndex(address owner) private view {
        TvmCell codeIndexOwner = _buildIndexCode(_addrRoot, owner);
        TvmCell stateIndexOwner = _buildIndexState(codeIndexOwner, address(this));
        new Index{stateInit: stateIndexOwner, value: 0.4 ton}(_addrRoot);

        TvmCell codeIndexOwnerRoot = _buildIndexCode(address(0), owner);
        TvmCell stateIndexOwnerRoot = _buildIndexState(codeIndexOwnerRoot, address(this));
        new Index{stateInit: stateIndexOwnerRoot, value: 0.4 ton}(_addrRoot);
    }

    function redeployIndex() public view onlyOwner {
        require (msg.value >= Constants.MIN_FOR_DEPLOY_INDEXES);
        tvm.accept();

        address oldIndexOwner = resolveIndex(address(0), address(this), _addrOwner);
        IIndex(oldIndexOwner).destruct();
        address oldIndexOwnerRoot = resolveIndex(_addrRoot, address(this), _addrOwner);
        IIndex(oldIndexOwnerRoot).destruct();

        TvmCell codeIndexOwner = _buildIndexCode(_addrRoot, _addrOwner) ;
        TvmCell stateIndexOwner = _buildIndexState(codeIndexOwner, address(this));
        new Index{stateInit: stateIndexOwner, value: 0.4 ton}(_addrRoot);

        TvmCell codeIndexOwnerRoot = _buildIndexCode(address(0), _addrOwner);
        TvmCell stateIndexOwnerRoot = _buildIndexState(codeIndexOwnerRoot, address(this));
        new Index{stateInit: stateIndexOwnerRoot, value: 0.4 ton}(_addrRoot);
    }

    function setIndexCode(TvmCell codeIndex) public onlyOwner {
        tvm.accept();
        _codeIndex = codeIndex;
    }

    function getInfo() public view override returns (
        address addrRoot,
        address addrOwner,
        address addrData
    ) {
        addrRoot = _addrRoot;
        addrOwner = _addrOwner;
        addrData = address(this);
    }

    function getInfoResponsible() public view responsible returns (
        address addrRoot,
        address addrOwner,
        address addrData
    ) {
        return {value: 0, flag: 64} (_addrRoot, _addrOwner, address(this));
    }

    function getOwner() public view override returns(address addrOwner) {
        addrOwner = _addrOwner;
    }

    modifier onlyOwner {
        require(msg.sender == _addrOwner);
        _;
    }

}