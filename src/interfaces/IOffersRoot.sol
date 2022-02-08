pragma ton-solidity ^0.47.0;

interface IOffersRoot {
    function changeDeploymentFee(uint128 deploymentFee) external;
    function changeMarketFee(uint128 marketFee) external;
    function setOfferCode(TvmCell offerCode) external;
}