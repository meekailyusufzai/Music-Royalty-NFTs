// SPDX-License-Identifier: M
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MusicRoyaltyNFTs is ERC721, ERC721URIStorage, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct MusicTrack {
        string title;
        string artist;
        uint256 royaltyPercentage; // Percentage of royalties (in basis points, 100 = 1%)
        uint256 totalEarnings;
        address originalCreator;
        bool isActive;
    }

    mapping(uint256 => MusicTrack) public musicTracks;
    mapping(uint256 => address[]) public royaltyHolders;
    mapping(uint256 => mapping(address => uint256)) public holderShares; // tokenId => holder => share percentage
    
    event MusicNFTMinted(uint256 indexed tokenId, string title, string artist, address creator);
    event RoyaltyDistributed(uint256 indexed tokenId, uint256 amount, uint256 timestamp);
    event SharesUpdated(uint256 indexed tokenId, address holder, uint256 newShare);

    constructor() ERC721("Music Royalty NFTs", "MRNFT") {}

    /**
     * @dev Mint a new Music Royalty NFT
     * @param to Address to mint the NFT to
     * @param title Title of the music track
     * @param artist Artist name
     * @param royaltyPercentage Royalty percentage in basis points (100 = 1%)
     * @param tokenURI Metadata URI for the NFT
     */
    function mintMusicNFT(
        address to,
        string memory title,
        string memory artist,
        uint256 royaltyPercentage,
        string memory tokenURI
    ) external returns (uint256) {
        require(royaltyPercentage > 0 && royaltyPercentage <= 10000, "Invalid royalty percentage");
        require(bytes(title).length > 0, "Title cannot be empty");
        require(bytes(artist).length > 0, "Artist cannot be empty");

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(to, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        musicTracks[newTokenId] = MusicTrack({
            title: title,
            artist: artist,
            royaltyPercentage: royaltyPercentage,
            totalEarnings: 0,
            originalCreator: msg.sender,
            isActive: true
        });

        // Initialize the minter as the sole royalty holder with 100% share
        royaltyHolders[newTokenId].push(to);
        holderShares[newTokenId][to] = 10000; // 100% in basis points

        emit MusicNFTMinted(newTokenId, title, artist, msg.sender);
        return newTokenId;
    }

    /**
     * @dev Distribute royalties to NFT holders
     * @param tokenId The token ID to distribute royalties for
     */
    function distributeRoyalties(uint256 tokenId) external payable nonReentrant {
        require(_exists(tokenId), "Token does not exist");
        require(msg.value > 0, "No royalties to distribute");
        require(musicTracks[tokenId].isActive, "Track is not active");

        uint256 totalAmount = msg.value;
        musicTracks[tokenId].totalEarnings += totalAmount;

        address[] memory holders = royaltyHolders[tokenId];
        
        for (uint256 i = 0; i < holders.length; i++) {
            address holder = holders[i];
            uint256 share = holderShares[tokenId][holder];
            
            if (share > 0) {
                uint256 payment = (totalAmount * share) / 10000;
                (bool success, ) = payable(holder).call{value: payment}("");
                require(success, "Payment failed");
            }
        }

        emit RoyaltyDistributed(tokenId, totalAmount, block.timestamp);
    }

    /**
     * @dev Update royalty shares for a token (only owner of the token can call this)
     * @param tokenId The token ID
     * @param newHolders Array of new holder addresses
     * @param newShares Array of new share percentages (in basis points)
     */
    function updateRoyaltyShares(
        uint256 tokenId,
        address[] memory newHolders,
        uint256[] memory newShares
    ) external {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Only token owner can update shares");
        require(newHolders.length == newShares.length, "Arrays length mismatch");

        // Clear existing holders
        address[] storage currentHolders = royaltyHolders[tokenId];
        for (uint256 i = 0; i < currentHolders.length; i++) {
            holderShares[tokenId][currentHolders[i]] = 0;
        }
        delete royaltyHolders[tokenId];

        // Validate and set new shares
        uint256 totalShares = 0;
        for (uint256 i = 0; i < newHolders.length; i++) {
            require(newHolders[i] != address(0), "Invalid holder address");
            require(newShares[i] > 0, "Share must be greater than 0");
            totalShares += newShares[i];
        }
        require(totalShares == 10000, "Total shares must equal 100%");

        // Set new holders and shares
        for (uint256 i = 0; i < newHolders.length; i++) {
            royaltyHolders[tokenId].push(newHolders[i]);
            holderShares[tokenId][newHolders[i]] = newShares[i];
            emit SharesUpdated(tokenId, newHolders[i], newShares[i]);
        }
    }

    // View functions
    function getMusicTrack(uint256 tokenId) external view returns (MusicTrack memory) {
        require(_exists(tokenId), "Token does not exist");
        return musicTracks[tokenId];
    }

    function getRoyaltyHolders(uint256 tokenId) external view returns (address[] memory) {
        require(_exists(tokenId), "Token does not exist");
        return royaltyHolders[tokenId];
    }

    function getHolderShare(uint256 tokenId, address holder) external view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        return holderShares[tokenId][holder];
    }

    function getCurrentTokenId() external view returns (uint256) {
        return _tokenIds.current();
    }

    // Override functions
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
