pragma ton-solidity >=0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import './resolvers/IndexResolver.sol';
import './interfaces/IData.sol';
import './errors/DataErrors.sol';

contract Data is IData, IndexResolver {
    address _addrRoot;
    address _addrOwner;

    uint128 _indexDeployValue = 0.4 ton;
    uint128 _processingValue = 0.2 ton;

    uint256 static _id;

    event tokenWasMinted(address owner);
    event ownershipTransferred(address oldOwner, address newOwner);

    constructor(
        address addrOwner, 
        TvmCell codeIndex,
        uint128 indexDeployValue,
        uint128 processingValue
    ) public {
        optional(TvmCell) optSalt = tvm.codeSalt(tvm.code());
        require(optSalt.hasValue(), DataErrors.value_is_empty);
        (address addrRoot) = optSalt.get().toSlice().decode(address);
        require(msg.sender == addrRoot, DataErrors.sender_is_not_root);
        require(msg.value >= (_indexDeployValue * 2) + _processingValue, DataErrors.value_less_than_required);
        tvm.accept();
        _addrRoot = addrRoot;
        _addrOwner = addrOwner;
        _codeIndex = codeIndex;
        _indexDeployValue = indexDeployValue;
        _processingValue = processingValue;

        emit tokenWasMinted(addrOwner);

        deployIndex(addrOwner);
    }

    function transferOwnership(address addrTo) public override {
        require(msg.sender == _addrOwner, DataErrors.sender_is_not_owner);
        require(msg.value >= (_indexDeployValue * 2) + _processingValue, DataErrors.value_less_than_required);
        require(addrTo != address(0), DataErrors.value_is_empty);

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
        new Index{stateInit: stateIndexOwner, value: _indexDeployValue}(_addrRoot);

        TvmCell codeIndexOwnerRoot = _buildIndexCode(address(0), owner);
        TvmCell stateIndexOwnerRoot = _buildIndexState(codeIndexOwnerRoot, address(this));
        new Index{stateInit: stateIndexOwnerRoot, value: _indexDeployValue}(_addrRoot);
    }

    function redeployIndex() public view onlyOwner {
        require (msg.value >= (_indexDeployValue * 2) + _processingValue, DataErrors.value_less_than_required);
        tvm.accept();

        address oldIndexOwner = resolveIndex(address(0), address(this), _addrOwner);
        IIndex(oldIndexOwner).destruct();
        address oldIndexOwnerRoot = resolveIndex(_addrRoot, address(this), _addrOwner);
        IIndex(oldIndexOwnerRoot).destruct();

        deployIndex(_addrOwner);
    }

    function setIndexCode(TvmCell codeIndex) public onlyOwner {
        tvm.accept();
        _codeIndex = codeIndex;
    }

    /// @return addrRoot address NftRoot
    /// @return addrOwner address contract owner ( _addrOwner )
    /// @return addrData address of storage contract (since the nft content is stored outside the blockchain, we simply return address(this), this parameter is not used in any way)
    function getInfo() public view override returns (
        address addrRoot,
        address addrOwner,
        address addrData
    ) {
        addrRoot = _addrRoot;
        addrOwner = _addrOwner;
        addrData = address(this);
    }

    /// @notice used to get information by another contract
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

    function setIndexDeployValue(uint128 indexDeployValue) public onlyOwner {
        tvm.accept();
        _indexDeployValue = indexDeployValue;
    } 

    function setProcessingValue(uint128 processingValue) public onlyOwner {
        tvm.accept();
        _processingValue = processingValue;
    } 

    function getIndexDeployValue() public view returns(uint128) {
        return _indexDeployValue;
    }

    function getProcessingValue() public view returns(uint128) {
        return _processingValue;
    }

}