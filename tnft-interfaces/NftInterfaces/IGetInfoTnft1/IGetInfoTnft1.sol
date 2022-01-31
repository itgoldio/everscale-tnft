pragma ton-solidity = 0.47.0;

pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

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