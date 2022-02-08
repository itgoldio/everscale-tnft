pragma ton-solidity >= 0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import '../Nft.sol';

// TODO: Test the hypothesis that inline will be more profitable in a given situation

contract NftResolver {
    TvmCell _codeNft;

    function resolveCodeHashNft() public view returns (uint256 codeHashData) {
        return tvm.hash(_buildNftCode(address(this)));
    }

    function resolveNft(
        address addrRoot,
        uint256 id
    ) public view returns (address addrNft) {
        TvmCell code = _buildNftCode(addrRoot);
        TvmCell state = _buildNftState(code, id);
        uint256 hashState = tvm.hash(state);
        addrNft = address.makeAddrStd(0, hashState);
    }

    function _buildNftCode(address addrRoot) internal virtual view returns (TvmCell) {
        TvmBuilder salt;
        salt.store(addrRoot);
        return tvm.setCodeSalt(_codeNft, salt.toCell());
    }

    function _buildNftState(
        TvmCell code,
        uint256 id
    ) internal virtual pure returns (TvmCell) {
        return tvm.buildStateInit({
            contr: Nft,
            varInit: {_id: id},
            code: code
        });
    }
}