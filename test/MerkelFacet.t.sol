import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "../contracts/facets/MerkleFacet.sol";
import "../contracts/Diamond.sol";

import "./helpers/DiamondUtils.sol";
import "./helpers/GetProof.sol";

contract MerkleFacetTest is DiamondUtils, IDiamondCut, GetProof {
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    MerkleFacet merkleF;
    bytes32 merkleroot = 0x2d9c0cce19ccdec8e1da991223f237448e29a5fbac2ed2ef408455db9cb550bb;
    address owner;
    address user1;
    address user2;

    function setUp() public {
        // vm.startPrank(address(0x10));
        //deploy facets
        owner = address(this);
        user1 = address(1);
        user2 = address(10); // in the mint root
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
    }

    // function testMerkleRoot() external {
    //     bytes32[] memory proofArray = getProof(address(1));
    //     // logBytes32Array(proofArray[1]);
    // }

    function testMerkleRoot() public {
        assertEq(MerkleFacet(address(diamond)).merkleRoot(), merkleroot, "Merkle root should be set correctly");
    }

    function testMintPresale() public {
        bytes32[] memory proof = getProof(user1);

        vm.deal(user1, 1 ether);
        vm.prank(user1);
        MerkleFacet(address(diamond)).mintPresale{value: 0.034 ether}(proof);

        assertEq(MerkleFacet(address(diamond)).balanceOf(user1), 1, "User should have 1 NFT after minting");
    }

    function testCannotMintTwice() public {
        bytes32[] memory proof = getProof(user1);

        vm.deal(user1, 2 ether);
        vm.startPrank(user1);

        MerkleFacet(address(diamond)).mintPresale{value: 0.034 ether}(proof);

        vm.expectRevert(abi.encodeWithSignature("AlreadyMinted()"));
        MerkleFacet(address(diamond)).mintPresale{value: 0.034 ether}(proof);

        vm.stopPrank();
    }

    function testCannotMintWithInvalidProof() public {
        bytes32[] memory proof = getProof(user2);

        vm.deal(user1, 1 ether);
        vm.prank(user1);

        vm.expectRevert(abi.encodeWithSignature("InvalidProof()"));
        MerkleFacet(address(diamond)).mintPresale{value: 0.034 ether}(proof);
    }

    function testMintMultipleNFTs() public {
        bytes32[] memory proof = getProof(user1);

        vm.deal(user1, 1 ether);
        vm.prank(user1);
        MerkleFacet(address(diamond)).mintPresale{value: 0.3 ether}(proof);

        assertEq(MerkleFacet(address(diamond)).balanceOf(user1), 9, "User should have 9 NFTs after minting");
    }

    function testUpdateMerkleRoot() public {
        bytes32 newMerkleRoot = 0x1234567890123456789012345678901234567890123456789012345678901234;

        MerkleFacet(address(diamond)).updateMerkleRoot(newMerkleRoot);

        assertEq(MerkleFacet(address(diamond)).merkleRoot(), newMerkleRoot, "Merkle root should be updated");
    }

    function testCannotUpdateMerkleRootAsNonOwner() public {
        bytes32 newMerkleRoot = 0x1234567890123456789012345678901234567890123456789012345678901234;

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSignature("NotDiamondOwner()"));
        MerkleFacet(address(diamond)).updateMerkleRoot(newMerkleRoot);
    }

    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external override {}
}
