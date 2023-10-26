pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

contract FoundryStateCheck is TestBase {
    struct TxData {
        TxDataDebug debug;
        address from;
        bytes input;
        bytes32 outputHash;
        address to;
    }

    struct TxDataDebug {
        string call;
        string expected;
        string output;
        string id;
    }

    using stdJson for string;

    string private testId;
    uint private txIndex;
    string private testPath;
    string private expectationsFile;
    mapping(uint => TxData) txs;

    constructor(string memory path) {
        testPath = string.concat('./test/', path);
        expectationsFile = vm.readFile(string.concat(testPath, '/expectations.json'));
        bytes memory transactionRaw = expectationsFile.parseRaw(string.concat('.txs'));
        TxData[] memory transactions = abi.decode(transactionRaw, (TxData[]));

        for (uint i = 0; i < transactions.length; i++) {
            TxData memory transaction = transactions[i];
            txs[i] = transaction;
        }
    }

    modifier expectations(string memory id) {
        testId = string.concat("['", id, "']");
        txIndex = 0;
        _;
    }

    function assertUnchanged() public virtual {
        bytes memory transactionRaw = expectationsFile.parseRaw(string.concat('.tests.', testId, '[', vm.toString(txIndex), ']'));
        uint[] memory transactions = abi.decode(transactionRaw, (uint[]));

        for (uint i = 0; i < transactions.length; i++) {
            TxData memory transaction = txs[transactions[i]];

            vm.prank(transaction.from);
            (bool success, bytes memory ret) = transaction.to.staticcall(transaction.input);
            if (!success) {
                revert(string.concat('Call ', transaction.debug.call, ' reverted: ', vm.toString(ret)));
            }
            if (keccak256(ret) != transaction.outputHash) {
                revert(string.concat('Call ', transaction.debug.call, ' return value did not match expected: ', transaction.debug.expected));
            }
        }
        txIndex += 1;
    }
}
