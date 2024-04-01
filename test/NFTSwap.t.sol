// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {NFTSwap} from "../src/NFTSwap.sol";
import {MyERC721} from "../src/MyERC721.sol";

contract NFTSwapTest is Test {
    NFTSwap public nftSwap;
    MyERC721 public mockNFTA;
    MyERC721 public mockNFTB;
    address public INITIATOR = makeAddr("initiator");
    address public COUNTERPARTY = makeAddr("counterparty");
    uint256 public idA = 1;
    uint256 public idB = 2;

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

    function setUp() public {
        vm.startPrank(INITIATOR);
        nftSwap = new NFTSwap();
        mockNFTA = new MyERC721(INITIATOR);
        vm.stopPrank();
        vm.startPrank(COUNTERPARTY);
        mockNFTB = new MyERC721(COUNTERPARTY);
        vm.stopPrank();
    }

    function testCreateSwap() public {
        vm.startPrank(INITIATOR);
        mockNFTA.safeMint(INITIATOR, idA);
        vm.stopPrank();
        vm.startPrank(COUNTERPARTY);
        mockNFTB.safeMint(COUNTERPARTY, idB);
        vm.stopPrank();
        vm.startPrank(INITIATOR);
        nftSwap.createSwap(
            COUNTERPARTY,
            address(mockNFTA),
            idA,
            address(mockNFTB),
            idB
        );

        bytes32 swapId = keccak256(
            abi.encodePacked(
                INITIATOR,
                COUNTERPARTY,
                mockNFTA,
                idA,
                mockNFTB,
                idB
            )
        );
        assertEq(nftSwap.getSwap(swapId).initiator, INITIATOR);
        vm.expectRevert();
        nftSwap.createSwap(
            COUNTERPARTY,
            address(mockNFTA),
            idA,
            address(mockNFTB),
            idB
        );
    }

    function testSwapCreatedEvent() public {
        vm.startPrank(INITIATOR);
        bytes32 swapId = keccak256(
            abi.encodePacked(
                INITIATOR,
                COUNTERPARTY,
                mockNFTA,
                idA,
                mockNFTB,
                idB
            )
        );
        vm.expectEmit();
        emit SwapCreated(
            swapId,
            INITIATOR,
            COUNTERPARTY,
            address(mockNFTA),
            idA,
            address(mockNFTB),
            idB
        );
        nftSwap.createSwap(
            COUNTERPARTY,
            address(mockNFTA),
            idA,
            address(mockNFTB),
            idB
        );
        vm.stopPrank();
    }

    function testDepositNFT() public {
        vm.startPrank(INITIATOR);
        mockNFTA.safeMint(INITIATOR, idA);
        vm.stopPrank();
        vm.startPrank(COUNTERPARTY);
        mockNFTB.safeMint(COUNTERPARTY, idB);
        vm.stopPrank();

        vm.startPrank(INITIATOR);
        nftSwap.createSwap(
            COUNTERPARTY,
            address(mockNFTA),
            idA,
            address(mockNFTB),
            idB
        );

        bytes32 swapId = keccak256(
            abi.encodePacked(
                INITIATOR,
                COUNTERPARTY,
                mockNFTA,
                idA,
                mockNFTB,
                idB
            )
        );
        assertEq(nftSwap.getSwap(swapId).initiator, INITIATOR);
        mockNFTA.approve(address(nftSwap), idA);
        nftSwap.depositNFT(swapId, idA);
        vm.stopPrank();
        assertEq(nftSwap.getSwap(swapId).tokenADeposited, true);
        vm.startPrank(COUNTERPARTY);
        mockNFTB.approve(address(nftSwap), idB);
        nftSwap.depositNFT(swapId, idB);
        vm.stopPrank();
        assertEq(nftSwap.getSwap(swapId).tokenBDeposited, true);
    }

    function testSwapNFT() public {
        vm.startPrank(INITIATOR);
        mockNFTA.safeMint(INITIATOR, idA);
        vm.stopPrank();
        vm.startPrank(COUNTERPARTY);
        mockNFTB.safeMint(COUNTERPARTY, idB);
        vm.stopPrank();

        vm.startPrank(INITIATOR);
        nftSwap.createSwap(
            COUNTERPARTY,
            address(mockNFTA),
            idA,
            address(mockNFTB),
            idB
        );

        bytes32 swapId = keccak256(
            abi.encodePacked(
                INITIATOR,
                COUNTERPARTY,
                mockNFTA,
                idA,
                mockNFTB,
                idB
            )
        );
        assertEq(nftSwap.getSwap(swapId).initiator, INITIATOR);
        mockNFTA.approve(address(nftSwap), idA);
        nftSwap.depositNFT(swapId, idA);
        vm.stopPrank();
        assertEq(nftSwap.getSwap(swapId).tokenADeposited, true);
        vm.startPrank(COUNTERPARTY);
        mockNFTB.approve(address(nftSwap), idB);
        nftSwap.depositNFT(swapId, idB);
        vm.stopPrank();
        assertEq(nftSwap.getSwap(swapId).tokenBDeposited, true);

        vm.prank(INITIATOR);
        nftSwap.swapNFT(swapId);
    }

    // function testSwapNotExists(bytes32 _swapId) public {
    //     s_swaps[_swapId].tokenA == address(0);
    //     s_swaps[_swapId].tokenB == address(0);

    //     (bool success, ) = address(nftSwap).call(abi.encodeWithSignature("swapNFT(bytes32)", swapId));
    //     assertFalse(success, "Swap does not exist");
    // }

    // function testSwapAlreadyExists() public {
    //     address counterparty = address(this);
    //     address tokenA = address(mockNFTA);
    //     uint256 idA = 1;
    //     address tokenB = address(mockNFTB);
    //     uint256 idB = 1;

    //     nftSwap.createSwap(counterparty, tokenA, idA, tokenB, idB);
    //     (bool success, ) = address(nftSwap).call(abi.encodeWithSignature("createSwap(address,address,uint256,address,uint256)", counterparty, tokenA, idA, tokenB, idB));
    //     assertFalse(success, "Should revert for already existing swap");
    // }

    // function testInvalidNFTDeposit() public {
    //     address counterparty = address(this);
    //     address tokenA = address(mockNFTA);
    //     uint256 idA = 1;
    //     address tokenB = address(mockNFTB);
    //     uint256 idB = 1;

    //     nftSwap.createSwap(counterparty, tokenA, idA, tokenB, idB);
    //     bytes32 swapId = keccak256(abi.encodePacked(address(this), counterparty, tokenA, idA, tokenB, idB));

    //     (bool success, ) = address(nftSwap).call(abi.encodeWithSignature("depositNFT(bytes32,uint256)", swapId, 2));
    //     assertFalse(success, "Should revert for invalid NFT deposit");
    // }

    // function testNotAuthorizedDeposit() public {
    //     address counterparty = address(this);
    //     address tokenA = address(mockNFTA);
    //     uint256 idA = 1;
    //     address tokenB = address(mockNFTB);
    //     uint256 idB = 1;

    //     nftSwap.createSwap(counterparty, tokenA, idA, tokenB, idB);
    //     bytes32 swapId = keccak256(abi.encodePacked(address(this), counterparty, tokenA, idA, tokenB, idB));

    //     (bool success, ) = address(nftSwap).call(abi.encodeWithSignature("depositNFT(bytes32,uint256)", swapId, idA));
    //     assertFalse(success, "Should revert for unauthorized NFT deposit");
    // }

    // function testBothNFTNotDeposited() public {
    //     address counterparty = address(this);
    //     address tokenA = address(mockNFTA);
    //     uint256 idA = 1;
    //     address tokenB = address(mockNFTB);
    //     uint256 idB = 1;

    //     nftSwap.createSwap(counterparty, tokenA, idA, tokenB, idB);
    //     bytes32 swapId = keccak256(abi.encodePacked(address(this), counterparty, tokenA, idA, tokenB, idB));

    //     (bool success, ) = address(nftSwap).call(abi.encodeWithSignature("swapNFT(bytes32)", swapId));
    //     assertFalse(success, "Should revert for both NFT not deposited");
    // }
}
