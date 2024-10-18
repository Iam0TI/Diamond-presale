// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "../contracts/facets/MerkleFacet.sol";
import "../contracts/Diamond.sol";

import "./helpers/DiamondUtils.sol";
import "./helpers/GetProof.sol";

contract DiamondDeployer is DiamondUtils, IDiamondCut, GetProof {
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    MerkleFacet merkleF;
    bytes32 merkleroot = 0x2d9c0cce19ccdec8e1da991223f237448e29a5fbac2ed2ef408455db9cb550bb;

    function testDeployDiamond() public {
        // vm.startPrank(address(0x10));
        //deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet), "Program Analysis", "PA", merkleroot);
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        merkleF = new MerkleFacet();

        //upgrade diamond with facets

        //build cut struct
        FacetCut[] memory cut = new FacetCut[](3);

        cut[0] = (
            FacetCut({
                facetAddress: address(dLoupe),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("DiamondLoupeFacet")
            })
        );

        cut[1] = (
            FacetCut({
                facetAddress: address(ownerF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("OwnershipFacet")
            })
        );
        cut[2] = (
            FacetCut({
                facetAddress: address(merkleF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("MerkleFacet")
            })
        );

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");

        //call a function
        DiamondLoupeFacet(address(diamond)).facetAddresses();

        bytes32[] memory proofArray = getProof(address(1));
        // logBytes32Array(proofArray[1]);
    }

    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external override {}
}
