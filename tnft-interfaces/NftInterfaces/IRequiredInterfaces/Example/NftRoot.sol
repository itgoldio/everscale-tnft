pragma ton-solidity >=0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import '../../../vendoring/resolvers/IndexResolver.sol';
import 'DataResolver.sol';

import '../../../vendoring/IndexBasis.sol';

import '../../../vendoring/interfaces/IData.sol';
import '../../../vendoring/interfaces/IIndexBasis.sol';

import '../../../vendoring/libraries/Constants.sol';
import '../../../vendoring/errors/NftRootErrors.sol';


contract NftRoot is DataResolver, IndexResolver {

    uint256 _totalMinted;
    address _addrIndexBasis;

    event tokenWasMinted(address nftAddr, address creatorAddr);

    constructor(TvmCell codeIndex, TvmCell codeData) public {
        require(tvm.pubkey() != 0, NftRootErrors.pubkey_is_empty);
        tvm.accept();
        _codeIndex = codeIndex;
        _codeData = codeData;
    }

    function mintNft() public {
        require(msg.value > Constants.MIN_FOR_DEPLOY_DATA, NftRootErrors.value_less_than_required);
        TvmCell codeData = _buildDataCode(address(this));
        TvmCell stateData = _buildDataState(codeData, _totalMinted);
        address dataAddr = new Data{
            stateInit: stateData,
            value: 1.1 ton
            }(
                msg.sender, 
                _codeIndex
            ); 

        emit tokenWasMinted(dataAddr, msg.sender);

        _totalMinted++;
    }

    function deployIndexBasis(TvmCell codeIndexBasis) public checkPubkey {
        require(msg.value > 0.5 ton, NftRootErrors.value_less_than_required);
        uint256 codeHashData = resolveCodeHashData();
        TvmCell state = tvm.buildStateInit({
            contr: IndexBasis,
            varInit: {
                _codeHashData: codeHashData,
                _addrRoot: address(this)
            },
            code: codeIndexBasis
        });
        _addrIndexBasis = new IndexBasis{stateInit: state, value: 0.4 ton}();
    }

    function destructIndexBasis() public view checkPubkey {
        require(_addrIndexBasis != address(0), NftRootErrors.index_not_deployed);
        IIndexBasis(_addrIndexBasis).destruct();
    }

    modifier checkPubkey {
        require(msg.pubkey() == tvm.pubkey(), NftRootErrors.not_my_pubkey);
        _;
    }
}