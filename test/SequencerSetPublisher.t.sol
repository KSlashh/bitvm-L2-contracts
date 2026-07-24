// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {Test} from "forge-std/Test.sol";
import {StdStorage, stdStorage} from "forge-std/StdStorage.sol";
import {SequencerSetPublisher} from "../src/SequencerSetPublisher.sol";
import {ISequencerSetPublisher} from "../src/interfaces/ISequencerSetPublisher.sol";
import {console} from "forge-std/console.sol";

contract SequencerSetPublisherTest is Test {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;
    using stdStorage for StdStorage;

    SequencerSetPublisher sspublisher;

    address owner = vm.addr(1);
    address[] initPublishers;
    uint256[] batch;
    uint256[] batch1;
    uint256[] batch2;

    function _get_pubkey_from_prvkey(uint256 number) internal pure returns (bytes[] memory) {
        bytes[5] memory newPublisherPubkeysConstant;
        newPublisherPubkeysConstant[0] = hex"031b84c5567b126440995d3ed5aaba0565d71e1834604819ff9c17f5e9d5dd078f";
        newPublisherPubkeysConstant[1] = hex"024d4b6cd1361032ca9bd2aeb9d900aa4d45d9ead80ac9423374c451a7254d0766";
        newPublisherPubkeysConstant[2] = hex"02531fe6068134503d2723133227c867ac8fa6c83c537e9a44c3c5bdbdcb1fe337";
        newPublisherPubkeysConstant[3] = hex"03462779ad4aad39514614751a71085f2f10e1c7a593e4e030efb5b8721ce55b0b";
        newPublisherPubkeysConstant[4] = hex"0362c0a046dacce86ddd0343c6d3c7c79c2208ba0d9c9cf24a6d046d21d21f90f7";
        require(number <= newPublisherPubkeysConstant.length);

        bytes[] memory newPublisherPubkeys = new bytes[](number);
        for (uint256 i = 0; i < number; i++) {
            newPublisherPubkeys[i] = newPublisherPubkeysConstant[i];
        }

        return newPublisherPubkeys;
    }

    function setUp() public {
        batch = new uint256[](3);
        batch[0] = 11;
        batch[1] = 12;
        batch[2] = 13;

        batch1 = new uint256[](5);
        batch1[0] = 21;
        batch1[1] = 22;
        batch1[2] = 23;
        batch1[3] = 24;
        batch1[4] = 25;

        batch2 = new uint256[](4);
        batch2[0] = 31;
        batch2[1] = 32;
        batch2[2] = 33;
        batch2[3] = 34;

        initPublishers = new address[](3);
        initPublishers[0] = vm.addr(batch[0]);
        console.log(batch[0]);
        initPublishers[1] = vm.addr(batch[1]);
        initPublishers[2] = vm.addr(batch[2]);

        sspublisher = new SequencerSetPublisher();

        sspublisher.initialize(owner);
    }

    function testInitialize() public view {
        // bytes memory key = sspublisher.getPublisher(initPublishers[0]);
        // assertEq(key.length, 33);
    }

    function run_publisher_update_test(
        uint256[] memory oldPublisherKeys,
        uint256[] memory newPublisherKeys,
        uint256 height
    ) public {
        // Removed logic
    }

    function testUpdatePublisherSet() public {
        // genesis sequencer set commit, publisher is not changed
        run_sequencer_update_test(batch, batch, 10, keccak256("commit1"), keccak256("set1"), keccak256("set2"));
        // publisher commit, sequencer set is not changed
        run_sequencer_update_test(batch, batch1, 11, keccak256("commit2"), keccak256("set2"), keccak256("set2"));
        // apply publisher update
        // assert(sspublisher.latestConfirmedHeight() == 0);
        // run_publisher_update_test(batch, batch1, 11);
        // assert(sspublisher.latestConfirmedHeight() == 11);

        // sequencer set commit, publisher is not changed
        run_sequencer_update_test(batch1, batch1, 12, keccak256("commit3"), keccak256("set2"), keccak256("set22"));
        run_sequencer_update_test(batch1, batch1, 13, keccak256("commit3"), keccak256("set22"), keccak256("set3"));
        // publisher commit, sequencer set is not changed
        run_sequencer_update_test(batch1, batch2, 17, keccak256("commit4"), keccak256("set3"), keccak256("set3"));
        // apply publisher update
        // assert(sspublisher.latestConfirmedHeight() == 11);
        // run_publisher_update_test(batch1, batch2, 17);
        // assert(sspublisher.latestConfirmedHeight() == 17);

        // sequencer set commit, publisher is not changed
        run_sequencer_update_test(batch2, batch2, 20, keccak256("commit5"), keccak256("set3"), keccak256("set4"));
    }

    function run_sequencer_update_test(
        uint256[] memory publisherKeys,
        uint256[] memory, /* nextPublisherKeys */
        uint256 height,
        bytes32 p2wshSigHash,
        bytes32, /* sequencerSetHash */
        bytes32 /* nextSequencerSetHash */
    ) public {
        // Generate a valid signature from ANY key (e.g. the first publisher key)
        // Since we don't check WHO signed it, just that it IS a signature.
        (, bytes32 r, bytes32 s) = vm.sign(publisherKeys[0], p2wshSigHash.toEthSignedMessageHash());
        bytes memory sig = abi.encodePacked(r, s);

        // Generate valid compressed BTC pubkey from private key
        // Hardcoded for pk=1 (which is publisherKeys[0] in setup)
        // X: 79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798
        // Y: 483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8 (even)
        // Compressed: 02 + X
        bytes memory btcPubkey;
        if (publisherKeys[0] == 11) {
            // batch[0] = 11
            // pk=11
            // X: 774ae7f858a9411e5ef4246b70c65aac5649980be5c17891bbec17895da008cb
            // Y: d984a032eb6b5e190243dd56d7b7b365372db1e2dff9d6a8301d74c9c953c61b (odd)
            btcPubkey = hex"03774ae7f858a9411e5ef4246b70c65aac5649980be5c17891bbec17895da008cb";
        } else if (publisherKeys[0] == 21) {
            // batch1[0] = 21
            // pk=21
            // X: 352bbf4a4cdd12564f93fa332ce333301d9ad40271f8107181340aef25be59d5
            // Y: 321eb4075348f534d59c18259dda3e1f4a1b3b2e71b1039c67bd3d8bcf81998c (even)
            btcPubkey = hex"02352bbf4a4cdd12564f93fa332ce333301d9ad40271f8107181340aef25be59d5";
        } else if (publisherKeys[0] == 31) {
            // batch2[0] = 31
            // pk=31
            // X: 6a245bf6dc698504c89a20cfded60853152b695336c28063b61c65cbd269e6b4
            // Y: e022cf42c2bd4a708b3f5126f16a24ad8b33ba48d0423b6efd5e6348100d8a82 (even)
            btcPubkey = hex"026a245bf6dc698504c89a20cfded60853152b695336c28063b61c65cbd269e6b4";
        } else {
            // Fallback to dummy if key is unknown (will fail verification)
            btcPubkey = new bytes(33);
        }

        ISequencerSetPublisher.SequencerSetUpdateWitness memory witness = ISequencerSetPublisher
            .SequencerSetUpdateWitness({sigHash: p2wshSigHash.toEthSignedMessageHash(), btcPubkey: btcPubkey, btcSig: sig});

        sspublisher.updateSequencerSet(height, witness);
    }

    function testUpdateSequencerSet() public {
        // New publishers
        run_sequencer_update_test(batch, batch, 10, keccak256("commit1"), keccak256("set1"), keccak256("set2"));
        run_sequencer_update_test(batch, batch, 11, keccak256("commit2"), keccak256("set2"), keccak256("set3"));
        run_sequencer_update_test(batch, batch, 12, keccak256("commit3"), keccak256("set3"), keccak256("set4"));
        run_sequencer_update_test(batch, batch, 13, keccak256("commit4"), keccak256("set4"), keccak256("set5"));
    }

    function testMultipleWitnesses() public {
        uint256 height = 100;
        bytes32 sigHash = keccak256("commit_multi");

        // Witness 1 (pk=11)
        run_sequencer_update_test(
            batch, // contains 11
            batch,
            height,
            sigHash,
            bytes32(0),
            bytes32(0)
        );

        // Witness 2 (pk=21)
        run_sequencer_update_test(
            batch1, // contains 21
            batch1,
            height,
            sigHash,
            bytes32(0),
            bytes32(0)
        );

        // Check if we have 2 witnesses
        ISequencerSetPublisher.SequencerSetUpdateWitness[] memory witnesses =
            sspublisher.getSequencerSetUpdateWitnesses(height);
        assertEq(witnesses.length, 2);

        // Try adding Witness 1 again (should fail)
        vm.expectRevert(ISequencerSetPublisher.DoubleCommit.selector);
        run_sequencer_update_test(batch, batch, height, sigHash, bytes32(0), bytes32(0));
    }
}
