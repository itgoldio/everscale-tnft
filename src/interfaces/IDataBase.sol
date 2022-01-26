pragma ton-solidity ^0.47.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import '../resolvers/IndexResolver.sol';
import '../errors/DataErrors.sol';

interface IDataBase {
    function redeployIndex() external;
    function setIndexCode(TvmCell codeIndex) external;
    function setIndexDeployValue(uint128 indexDeployValue) external;
    function getSummaryRoyalty() external returns(uint128 royaltyValue);
    function getRoyalty() external returns(mapping(address => uint128) royalty);
    function getIndexDeployValue() external returns(uint128);
    function getOwner() external returns(address addrOwner);
}

library DataBaseLib {
    int constant ID = 10;        
}

abstract contract DataBase is IDataBase, IndexResolver {

    uint256 static _id;

    address _addrRoot;
    address _addrOwner;

    uint128 _indexDeployValue;

    mapping(address => uint128) _royalty;

    event tokenWasMinted(address owner);

    function deployIndex(address owner) internal view {
        TvmCell codeIndexOwner = _buildIndexCode(_addrRoot, owner);
        TvmCell stateIndexOwner = _buildIndexState(codeIndexOwner, address(this));
        new Index{stateInit: stateIndexOwner, value: _indexDeployValue}(_addrRoot);

        TvmCell codeIndexOwnerRoot = _buildIndexCode(address(0), owner);
        TvmCell stateIndexOwnerRoot = _buildIndexState(codeIndexOwnerRoot, address(this));
        new Index{stateInit: stateIndexOwnerRoot, value: _indexDeployValue}(_addrRoot);
    }

    function destructIndex() internal view {
        tvm.accept();

        address oldIndexOwner = resolveIndex(address(0), address(this), _addrOwner);
        IIndex(oldIndexOwner).destruct();
        address oldIndexOwnerRoot = resolveIndex(_addrRoot, address(this), _addrOwner);
        IIndex(oldIndexOwnerRoot).destruct();
    }

    function redeployIndex() public override onlyOwner {
        require (msg.value >= (_indexDeployValue * 2), DataErrors.value_less_than_required);
        tvm.accept();

        destructIndex();
        deployIndex(_addrOwner);
    }

    function setIndexCode(TvmCell codeIndex) public override onlyOwner {
        tvm.accept();
        _codeIndex = codeIndex;
    }

    function setIndexDeployValue(uint128 indexDeployValue) public override onlyOwner {
        tvm.accept();
        _indexDeployValue = indexDeployValue;
    }

    function getSummaryRoyalty() public override returns(uint128 royaltyValue) {
        for ((address key, uint128 value) : _royalty) { // iteration over mapping 
            key; // disable warnings
            royaltyValue += value;
        }
    }

    function getRoyalty() public override returns(mapping(address => uint128) royalty) {
        return _royalty;
    }

    function getIndexDeployValue() public override returns(uint128) {
        return _indexDeployValue;
    }

    function getOwner() public override returns(address addrOwner) {
        addrOwner = _addrOwner;
    }

    modifier onlyOwner virtual {
        require(msg.sender == _addrOwner);
        _;
    }

}