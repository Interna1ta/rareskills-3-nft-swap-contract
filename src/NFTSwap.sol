// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

error NFTSwap__SwapNotExists(string message);
error NFTSwap__SwapAlreadyExists(string message);
error NFTSwap__NotAuthorized(string message);
error NFTSwap__InvalidNFT(string message);
error NFTSwap__BothNFTNotDeposited(string message);

contract NFTSwap {
    struct Swap {
        address initiator;
        address counterparty;
        address tokenA;
        uint256 idA;
        address tokenB;
        uint256 idB;
        bool tokenADeposited;
        bool tokenBDeposited;
    }

    mapping(bytes32 => Swap) public s_swaps;

    event SwapCreated(
        bytes32 swapId,
        address indexed initiator,
        address indexed counterparty,
        address tokenA,
        uint256 idA,
        address tokenB,
        uint256 idB
    );
    event NFTDeposited(
        bytes32 swapId,
        address depositor,
        address token,
        uint256 tokenId
    );
    event SwapCompleted(
        bytes32 swapId,
        address initiator,
        address counterparty,
        address tokenA,
        uint256 idA,
        address tokenB,
        uint256 idB
    );

    modifier onlyValidSwap(bytes32 _swapId) {
        if (
            s_swaps[_swapId].tokenA == address(0) ||
            s_swaps[_swapId].tokenB == address(0)
        ) {
            revert NFTSwap__SwapNotExists("Swap does not exist");
        }
        _;
    }

    function createSwap(
        address _counterparty,
        address _tokenA,
        uint256 _idA,
        address _tokenB,
        uint256 _idB
    ) external {
        bytes32 swapId = keccak256(
            abi.encodePacked(
                msg.sender,
                _counterparty,
                _tokenA,
                _idA,
                _tokenB,
                _idB
            )
        );
        if (
            s_swaps[swapId].tokenA != address(0) ||
            s_swaps[swapId].tokenB != address(0)
        ) {
            revert NFTSwap__SwapAlreadyExists("Swap already exists");
        }

        s_swaps[swapId] = Swap(
            msg.sender,
            _counterparty,
            _tokenA,
            _idA,
            _tokenB,
            _idB,
            false,
            false
        );

        emit SwapCreated(
            swapId,
            msg.sender,
            _counterparty,
            _tokenA,
            _idA,
            _tokenB,
            _idB
        );
    }

    function depositNFT(
        bytes32 _swapId,
        uint256 _tokenId
    ) external onlyValidSwap(_swapId) {
        Swap storage swap = s_swaps[_swapId];
        if (msg.sender != swap.initiator || msg.sender != swap.counterparty) {
            revert NFTSwap__NotAuthorized("Not authorized to deposit");
        }

        address token;

        if (msg.sender == swap.initiator) {
            if (swap.tokenADeposited || _tokenId != swap.idA) {
                revert NFTSwap__InvalidNFT("Invalid deposit");
            }
            IERC721(swap.tokenA).safeTransferFrom(
                msg.sender,
                address(this),
                _tokenId
            );
            token = swap.tokenA;
            swap.tokenADeposited = true;
        }

        if (msg.sender == swap.counterparty) {
            if (swap.tokenBDeposited || _tokenId != swap.idB) {
                revert NFTSwap__InvalidNFT("Invalid deposit");
            }
            IERC721(swap.tokenB).safeTransferFrom(
                msg.sender,
                address(this),
                _tokenId
            );
            token = swap.tokenB;
            swap.tokenBDeposited = true;
        }

        emit NFTDeposited(_swapId, msg.sender, token, _tokenId);
    }

    function swapNFT(bytes32 _swapId) external {
        if (!(s_swaps[_swapId].tokenADeposited)) {
            revert NFTSwap__BothNFTNotDeposited("Both NFTs not deposited");
        }
        if (!(s_swaps[_swapId].tokenBDeposited)) {
            revert NFTSwap__BothNFTNotDeposited("Both NFTs not deposited");
        }
        if (
            msg.sender != s_swaps[_swapId].initiator ||
            msg.sender != s_swaps[_swapId].counterparty
        ) {
            revert NFTSwap__NotAuthorized("Not authorized");
        }

        address initiatorToken = s_swaps[_swapId].tokenA;
        uint256 initiatorTokenId = s_swaps[_swapId].idA;
        address counterpartyToken = IERC721(s_swaps[_swapId].tokenB).ownerOf(
            s_swaps[_swapId].idB
        );

        IERC721(initiatorToken).safeTransferFrom(
            address(this),
            s_swaps[_swapId].counterparty,
            initiatorTokenId
        );
        IERC721(counterpartyToken).safeTransferFrom(
            address(this),
            s_swaps[_swapId].initiator,
            initiatorTokenId
        );

        delete s_swaps[_swapId];

        emit SwapCompleted(
            _swapId,
            s_swaps[_swapId].initiator,
            s_swaps[_swapId].counterparty,
            s_swaps[_swapId].tokenA,
            s_swaps[_swapId].idA,
            s_swaps[_swapId].tokenB,
            s_swaps[_swapId].idB
        );
    }
}
