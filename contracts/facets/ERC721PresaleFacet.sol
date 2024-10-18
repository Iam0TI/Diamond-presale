// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MerkleProof} from "../libraries/MerkleProof.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

contract ERC721PresaleFacet {
    error InvalidProof();
    error AlreadyMinted();

    event MintedNft(address indexed nftContract, address indexed to, uint256 indexed tokenId);

    // /* ========== Mutation Functions ========== */
    function mint(bytes32[] calldata proof, uint256 index, string memory uri) external {
        LibDiamond.DiamondStorage storage l = LibDiamond.diamondStorage();
        // check if already Minted
        require(l.mintCheckList[msg.sender] == false, AlreadyMinted());

        // verifing   the proof
        _verifyProof(proof, index, msg.sender);

        // set status to  Minted
        l.mintCheckList[msg.sender] = true;

        // _safeMint(msg.sender, index);
        // _setTokenURI(index, uri);

        emit MintedNft(address(this), msg.sender, index);
    }

    function updateMerkleRoot(bytes32 _newMerkleroot) external {
        LibDiamond.DiamondStorage storage l = LibDiamond.diamondStorage();
        l.merkleRoot = _newMerkleroot;
    }

    function _verifyProof(bytes32[] memory proof, uint256 tokenId, address addr) private view {
        LibDiamond.DiamondStorage storage l = LibDiamond.diamondStorage();

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(addr, tokenId))));

        require(MerkleProof.verify(proof, l.merkleRoot, leaf), InvalidProof());
    }
}
