pragma ton-solidity = 0.58.1;

pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import './resolvers/NftResolver.sol';

import './errors/NftRootErrors.sol';


contract NftRoot is NftResolver {

    uint256 _ownerPubkey;
    uint256 _totalMinted;

    /// _remainOnNft - the number of crystals that will remain after the entire mint 
    /// process is completed on the Nft contract
    uint128 _remainOnNft = 0.3 ton;

    event TokenWasMinted(address nftAddr, address creatorAddr);

    constructor(
        TvmCell codeNft, 
        uint256 ownerPubkey
    ) public {
        TvmCell empty;
        require(ownerPubkey != 0, NftRootErrors.pubkey_is_empty);
        require(codeNft != empty, NftRootErrors.value_is_empty);
        tvm.accept();

        _codeNft = codeNft;
        _ownerPubkey = ownerPubkey;
    }

    function mintNft(
        string dataName,
        string json
    ) public {
        tvm.rawReserve(msg.value, 1);

        TvmCell codeNft = _buildNftCode(address(this));
        TvmCell stateNft = _buildNftState(codeNft, _totalMinted);
        address nftAddr = new Nft{
            stateInit: stateNft,
            value: _remainOnNft
            }(
                msg.sender,
                json,
                dataName
            ); 

        emit TokenWasMinted(nftAddr, msg.sender);

        _totalMinted++;

        msg.sender.transfer({value: 0, flag: 128});
    }

    function withdraw(address to, uint128 value) public pure onlyOwner {
        require(address(this).balance > value, NftRootErrors.value_is_greater_than_the_balance);
        tvm.accept();
        to.transfer(value, true, 0);
    }

    function setRemainOnNft(uint128 remainOnNft) public onlyOwner {
        tvm.accept();
        _remainOnNft = remainOnNft;
    }   

    function getRemainOnNft() public view returns(uint128) {
        return _remainOnNft;
    }

    function getTotalMinted() public view returns(uint256) {
        return _totalMinted;
    }

    modifier onlyOwner {
        require(msg.pubkey() == _ownerPubkey, NftRootErrors.not_my_pubkey);
        _;
    }

}