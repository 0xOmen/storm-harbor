// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.9.0;

// Trustless escrow for exploited funds

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract stormHarbor {
    using SafeERC20 for IERC20;

    error Escrow__NotClaimable();
    error Escrow__NotDepositor();
    error Escrow__NoTokens();
    error Escrow__NotClaimant();
    error Escrow__InsufficientPayment();

    /**
     * @dev Struct that stores the details of each Escrow
     */
    struct Escrow {
        address depositor;
        address claimant;
        address exploitedTokenAddress;
        uint256 exploitedNFTId;
        uint256 exploitedTokenAmount;
        address bountyToken;
        uint256 bountyAmount;
        uint256 depositTime;
        bool isClaimable;
    }

    uint256 escrowNumber;

    mapping(uint256 => Escrow) public allEscrows;

    constructor() {}

    /**
     * @notice Creates an escrow storing ERC20 tokens
     * @param _claimant is the only address that can claim the tokens, can be set to null address and changed later
     * @param _exploitedTokenAddress the ERC20 token address of exploited funds
     * @param _exploitedTokenAmount the amount of ERC20 tokens to be returned to _claimant upon payment
     * @param _bountyToken the ERC20 token to be paid to the depositor for retrun of funds
     * @param _bountyAmount the minimum amount of _bountyToken to be paid to the depositor
     */
    function createTokenEscrow(
        address _claimant,
        address _exploitedTokenAddress,
        uint256 _exploitedTokenAmount,
        address _bountyToken,
        uint256 _bountyAmount
    ) public {
        if (_exploitedTokenAmount == 0) {
            revert Escrow__NoTokens();
        }
        escrowNumber++;

        allEscrows[escrowNumber].depositor = msg.sender;
        allEscrows[escrowNumber].claimant = _claimant;
        allEscrows[escrowNumber].exploitedTokenAddress = _exploitedTokenAddress;
        allEscrows[escrowNumber].exploitedTokenAmount = _exploitedTokenAmount;
        allEscrows[escrowNumber].bountyToken = _bountyToken;
        allEscrows[escrowNumber].bountyAmount = _bountyAmount;
        allEscrows[escrowNumber].depositTime = block.timestamp;
        allEscrows[escrowNumber].isClaimable = true;

        //emit EscrowCreated...

        IERC20(_exploitedTokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _exploitedTokenAmount
        );
    }

    /**
     * @notice Creates an escrow storing ERC721 NFTs
     * @param _claimant is the only address that can claim the tokens, can be set to null address and changed later
     * @param _exploitedTokenAddress the NFT address of exploited funds
     * @param _exploitedNFTId the ID number of the NFT to be returned to _claimant upon payment
     * @param _bountyToken the ERC20 token to be paid to the depositor for retrun of funds
     * @param _bountyAmount the minimum amount of _bountyToken to be paid to the depositor
     */
    function createNFTEscrow(
        address _claimant,
        address _exploitedTokenAddress,
        uint256 _exploitedNFTId,
        address _bountyToken,
        uint256 _bountyAmount
    ) public {
        escrowNumber++;

        allEscrows[escrowNumber].depositor = msg.sender;
        allEscrows[escrowNumber].claimant = _claimant;
        allEscrows[escrowNumber].exploitedTokenAddress = _exploitedTokenAddress;
        allEscrows[escrowNumber].exploitedNFTId = _exploitedNFTId;
        allEscrows[escrowNumber].bountyToken = _bountyToken;
        allEscrows[escrowNumber].bountyAmount = _bountyAmount;
        allEscrows[escrowNumber].depositTime = block.timestamp;
        allEscrows[escrowNumber].isClaimable = true;

        //emit EscrowCreated...

        ERC721(_exploitedTokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _exploitedNFTId
        );
    }

    /**
     * @notice rescinds the escrow by the escrow creator
     * @dev Escrows cannot be rescinded until 7 days after creation or a change in bountyAmount
     * @param _escrowNumber ID of the escrow to be closed
     */
    function cancelEscrow(uint256 _escrowNumber) public {
        if (
            allEscrows[_escrowNumber].isClaimable == false ||
            block.timestamp <= (allEscrows[_escrowNumber].depositTime + 604800)
        ) {
            revert Escrow__NotClaimable();
        }
        if (allEscrows[_escrowNumber].depositor != msg.sender) {
            revert Escrow__NotDepositor();
        }

        allEscrows[_escrowNumber].isClaimable = false;

        if (allEscrows[_escrowNumber].exploitedTokenAmount == 0) {
            ERC721(allEscrows[_escrowNumber].exploitedTokenAddress)
                .safeTransferFrom(
                    address(this),
                    allEscrows[_escrowNumber].depositor,
                    allEscrows[_escrowNumber].exploitedNFTId
                );
        } else {
            IERC20(allEscrows[_escrowNumber].exploitedTokenAddress)
                .safeTransfer(
                    msg.sender,
                    allEscrows[_escrowNumber].exploitedTokenAmount
                );
        }
    }

    /**
     * @notice changes the address that can claim the escrow
     * @dev allows depositors a way to await communication of a safe address to return funds to
     * @param _escrowNumber ID of the escrow to be closed
     * @param newClaimant address of the new escrow claimant
     */
    function setClaimant(uint256 _escrowNumber, address newClaimant) public {
        if (allEscrows[_escrowNumber].isClaimable == false) {
            revert Escrow__NotClaimable();
        }
        if (allEscrows[_escrowNumber].depositor != msg.sender) {
            revert Escrow__NotDepositor();
        }

        allEscrows[_escrowNumber].claimant = newClaimant;
    }

    /**
     * @notice changes the bounty amount required to claim escrowed funds
     * @dev this will block the ability of the despositor to cancel the escrow for 7 days
     * @param _escrowNumber ID of the escrow to be closed
     * @param _newBountyAmount new amount of the bountyToken that claimant must pay to claim exploited funds
     */
    function changeBountyAmount(
        uint256 _escrowNumber,
        uint256 _newBountyAmount
    ) public {
        if (allEscrows[_escrowNumber].isClaimable == false) {
            revert Escrow__NotClaimable();
        }
        if (allEscrows[_escrowNumber].depositor != msg.sender) {
            revert Escrow__NotDepositor();
        }

        allEscrows[_escrowNumber].bountyAmount = _newBountyAmount;
        allEscrows[_escrowNumber].depositTime = block.timestamp;
    }

    /**
     * @notice changes the bounty token required to claim escrowed funds
     * @dev this will block the ability of the despositor to cancel the escrow for 7 days
     * @param _escrowNumber ID of the escrow to be closed
     * @param _newBountyToken address of the new ERC20 token that claimant must pay to claim exploited funds
     * @param _newBountyAmount amount of the bountyToken that claimant must pay to claim exploited funds
     */
    function changeBountyToken(
        uint256 _escrowNumber,
        address _newBountyToken,
        uint256 _newBountyAmount
    ) public {
        if (allEscrows[_escrowNumber].isClaimable == false) {
            revert Escrow__NotClaimable();
        }
        if (allEscrows[_escrowNumber].depositor != msg.sender) {
            revert Escrow__NotDepositor();
        }

        allEscrows[_escrowNumber].bountyToken = _newBountyToken;
        allEscrows[_escrowNumber].bountyAmount = _newBountyAmount;
        allEscrows[_escrowNumber].depositTime = block.timestamp;
    }

    /**
     * @notice function to pay out the bounty and receive exploited funds
     * @param _escrowNumber ID of the escrow to be closed
     * @param _tokenAmount amount of the bountyToken claimant will pay to depositor, can be >= requested amount
     */
    function claimEscrow(uint256 _escrowNumber, uint256 _tokenAmount) public {
        if (allEscrows[_escrowNumber].isClaimable == false) {
            revert Escrow__NotClaimable();
        }
        if (allEscrows[_escrowNumber].claimant != msg.sender) {
            revert Escrow__NotClaimant();
        }
        if (_tokenAmount < allEscrows[_escrowNumber].bountyAmount) {
            revert Escrow__InsufficientPayment();
        }

        //potentially exploitable to reentrancy?
        IERC20(allEscrows[_escrowNumber].bountyToken).safeTransferFrom(
            msg.sender,
            allEscrows[_escrowNumber].depositor,
            _tokenAmount
        );

        allEscrows[_escrowNumber].isClaimable = false;

        if (allEscrows[_escrowNumber].exploitedTokenAmount == 0) {
            ERC721(allEscrows[_escrowNumber].exploitedTokenAddress)
                .safeTransferFrom(
                    address(this),
                    allEscrows[_escrowNumber].claimant,
                    allEscrows[_escrowNumber].exploitedNFTId
                );
        } else {
            IERC20(allEscrows[_escrowNumber].exploitedTokenAddress)
                .safeTransfer(
                    allEscrows[_escrowNumber].claimant,
                    allEscrows[_escrowNumber].exploitedTokenAmount
                );
        }
    }
}
