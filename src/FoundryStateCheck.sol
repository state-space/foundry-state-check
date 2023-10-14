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
    }

    using stdJson for string;

    string private testId;
    uint private txIndex;
    string private testPath;

    constructor(string memory path) {
        testPath = string.concat('./test/', path);
    }

    modifier expectations(string memory id) {
        testId = id;
        txIndex = 0;
        _;
    }

    function assertUnchanged() public virtual {
        string memory path = string.concat(testPath, '/expectations.json');
        string memory json = vm.readFile(path);
        bytes memory transactionsRaw = json.parseRaw(string.concat('.', testId, '[', vm.toString(txIndex), ']'));
        TxData[] memory transactions = abi.decode(transactionsRaw, (TxData[]));

        for (uint i = 0; i < transactions.length; i++) {
            TxData memory transaction = transactions[i];

            vm.prank(transaction.from);
            (bool success, bytes memory ret) = transaction.to.call(transaction.input);
            if (!success) {
                revert('Expected success');
            }
            if (keccak256(ret) != transaction.outputHash) {
                revert(string.concat('outputs do not match: ', transaction.debug.call));
            }
        }
        txIndex += 1;
    }
}