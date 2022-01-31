pragma ton-solidity = 0.47.0;

struct Meta {
    uint128 height;
    uint128 width;
    uint128 duration;
    string extra;
    string json;
}

interface IGetInfoTnft2 {
    function getInfo() external returns (
        string version,
        string name,
        string descriprion,
        address addrOwner,
        address addrAuthor,
        uint128 createdAt,
        address addrRoot,
        uint256 contentHash,
        string mimeType,
        uint8 chunks,
        uint128 chunkSize,
        uint128 size,
        Meta meta,
        uint128 royalty,
        uint128 royaltyMin
    );
}
