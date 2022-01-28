pragma ton-solidity ^0.47.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import '../INftBase/INftBase.sol';

interface IGetInfoTnft1 {
    function getInfo() external view returns (
        address addrRoot,
        address addrOwner,
        address addrNft
    );

    function getInfoResponsible() external view responsible returns (
        address addrRoot,
        address addrOwner,
        address addrNft
    );
}

library GetInfoTnft1Lib {
    int constant ID = 11;        
}

abstract contract GetInfoTnft1 is IGetInfoTnft1, NftBase {

     /// @return addrRoot address NftRoot
    /// @return addrOwner address contract owner ( _addrOwner )
    /// @return addrNft address of storage contract (since the nft content is stored outside the blockchain, we simply return address(this), this parameter is not used in any way)
    function getInfo() public override view returns (
        address addrRoot,
        address addrOwner,
        address addrNft
    ) {
        addrRoot = _addrRoot;
        addrOwner = _addrOwner;
        addrNft = address(this);
    }

    /// @notice used to get information by another contract
    function getInfoResponsible() public override view responsible returns (
        address addrRoot,
        address addrOwner,
        address addrNft
    ) {
        return {value: 0, flag: 64} (_addrRoot, _addrOwner, address(this));
    }


}