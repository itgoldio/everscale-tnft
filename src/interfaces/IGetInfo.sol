pragma ton-solidity ^0.47.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import './IDataBase.sol';

interface IGetInfo {
    function getInfo() external view returns (
        address addrRoot,
        address addrOwner,
        address addrData
    );

    function getInfoResponsible() external view responsible returns (
        address addrRoot,
        address addrOwner,
        address addrData
    );
}

library GetInfoLib {
    int constant ID = 11;        
}

abstract contract GetInfo is IGetInfo, DataBase {

     /// @return addrRoot address NftRoot
    /// @return addrOwner address contract owner ( _addrOwner )
    /// @return addrData address of storage contract (since the nft content is stored outside the blockchain, we simply return address(this), this parameter is not used in any way)
    function getInfo() public override view returns (
        address addrRoot,
        address addrOwner,
        address addrData
    ) {
        addrRoot = _addrRoot;
        addrOwner = _addrOwner;
        addrData = address(this);
    }

    /// @notice used to get information by another contract
    function getInfoResponsible() public override view responsible returns (
        address addrRoot,
        address addrOwner,
        address addrData
    ) {
        return {value: 0, flag: 64} (_addrRoot, _addrOwner, address(this));
    }


}