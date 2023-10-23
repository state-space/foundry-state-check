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
        uint numTxs = json.readUint(string.concat('.', testId, '[', vm.toString(txIndex), '].numTxs'));

        for (uint i = 0; i < numTxs; i++) {
            bytes memory transactionRaw = json.parseRaw(string.concat('.', testId, '[', vm.toString(txIndex), ']', '.txs[', vm.toString(i), ']'));
            TxData memory transaction = abi.decode(transactionRaw, (TxData));

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
