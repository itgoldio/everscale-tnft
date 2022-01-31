pragma ton-solidity = 0.47.0;

pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

interface IRequiredInterfaces {
    function getRequiredInterfaces() external returns(int[] requiredInterfaces);
    function getRequiredInterfacesResponsible() external responsible returns(int[] requiredInterfaces);
}