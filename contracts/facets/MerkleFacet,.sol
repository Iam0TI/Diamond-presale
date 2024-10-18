// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MerkleProof} from "../libraries/MerkleProof.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {ERC721PresaleFacet} from "./ERC721PresaleFacet.sol";

contract MerkleFacet is ERC721PresaleFacet {
    error InvalidProof();
    error AlreadyMinted();
    error IncorrectEthSent();

    event MintedNft(address indexed nftContract, address indexed to, uint256 indexed tokenId);

    uint256 public constant NFT_PRICE = 0.01 ether;
    // Number of NFTs per 1 ETH
    uint256 public constant NFTS_PER_ETHER = 30;

    // /* ========== Mutation Functions ========== */
    function mint(bytes32[] calldata proof) external payable {
        LibDiamond.DiamondStorage storage l = LibDiamond.diamondStorage();
        // check if already Minted
        require(l.mintCheckList[msg.sender] == false, AlreadyMinted());

        // verifing   the proof
        _verifyProof(proof, msg.sender);

        // Calculate the number of NFTs to mint based on the ETH sent
        uint256 numNfts = msg.value * NFTS_PER_ETHER / 1 ether;

        //a minimum of 0.01 ETH is sent
        require(msg.value >= NFT_PRICE, IncorrectEthSent());

        // set status to  Minted
        l.mintCheckList[msg.sender] = true;

        // Mint the NFTs
        for (uint256 i = 0; i < numNfts; i++) {
            l.index++;
            _safeMint(msg.sender, l.index + i);
            emit MintedNft(address(this), msg.sender, l.index + i);
        }
    }

    function updateMerkleRoot(bytes32 _newMerkleroot) external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage l = LibDiamond.diamondStorage();
        l.merkleRoot = _newMerkleroot;
    }

    function _verifyProof(bytes32[] memory proof, address addr) private view {
        LibDiamond.DiamondStorage storage l = LibDiamond.diamondStorage();

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(addr))));

        require(MerkleProof.verify(proof, l.merkleRoot, leaf), InvalidProof());
    }
}
