pragma ton-solidity ^0.47.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import '../../../src/resolvers/IndexResolver.sol';
import '../../../src/errors/NftErrors.sol';

interface INftBase {
    function setIndexDeployValue(uint128 indexDeployValue) external;
    function getSummaryRoyalty() external responsible returns(uint128 royaltyValue);
    function getRoyalty() external responsible returns(mapping(address => uint128) royalty);
    function getIndexDeployValue() external responsible returns(uint128);
    function getOwner() external responsible returns(address addrOwner);
}

library NftBaseLib {
    int constant ID = 10;        
}

abstract contract NftBase is INftBase, IndexResolver {

    uint256 static _id;

    address _addrRoot;
    address _addrOwner;

    uint128 _indexDeployValue;

    mapping(address => uint128) _royalty;

    event TokenWasMinted(address owner);

    function deployIndex(address owner) internal view {
        TvmCell codeIndexOwner = _buildIndexCode(_addrRoot, owner);
        TvmCell stateIndexOwner = _buildIndexState(codeIndexOwner, address(this));
        new Index{stateInit: stateIndexOwner, value: _indexDeployValue}(_addrRoot);

        TvmCell codeIndexOwnerRoot = _buildIndexCode(address(0), owner);
        TvmCell stateIndexOwnerRoot = _buildIndexState(codeIndexOwnerRoot, address(this));
        new Index{stateInit: stateIndexOwnerRoot, value: _indexDeployValue}(_addrRoot);
    }

    function destructIndex() internal view {
        address oldIndexOwner = resolveIndex(address(0), address(this), _addrOwner);
        IIndex(oldIndexOwner).destruct();
        address oldIndexOwnerRoot = resolveIndex(_addrRoot, address(this), _addrOwner);
        IIndex(oldIndexOwnerRoot).destruct();
    }

    function setIndexDeployValue(uint128 indexDeployValue) public override onlyOwner {
        tvm.rawReserve(msg.value, 1);
        _indexDeployValue = indexDeployValue;
    }

    function getSummaryRoyalty() public responsible override returns(uint128 royaltyValue) {
        for ((address key, uint128 value) : _royalty) { // iteration over mapping 
            key; // disable warnings
            royaltyValue += value;
        }

        return {value: 0, flag: 64} royaltyValue;
    }

    function getRoyalty() public responsible override returns(mapping(address => uint128) royalty) {
        return {value: 0, flag: 64} _royalty;
    }

    function getIndexDeployValue() public responsible override returns(uint128) {
        return {value: 0, flag: 64} _indexDeployValue;
    }

    function getOwner() public responsible override returns(address addrOwner) {
        return {value: 0, flag: 64} _addrOwner;
    }

    modifier onlyOwner virtual {
        require(msg.sender == _addrOwner, NftErrors.sender_is_not_owner);
        _;
    }

}