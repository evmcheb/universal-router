// SPDX-License-Identifier: None
library Calldata {
    function getUint8(uint256 offset) internal pure returns (uint8 val) {
        assembly {
            val := shr(0xf8, calldataload(offset))
        }
    }

    function getBytes1(uint256 offset) internal pure returns (bytes1 val) {
        assembly {
            val := shr(0xf8, calldataload(offset))
        }
    }

    function getUint16(uint256 offset) internal pure returns (uint16 val) {
        assembly {
            val := shr(0xf0, calldataload(offset))
        }
    }

    function getUint32(uint256 offset) internal pure returns (uint32 val) {
        assembly {
            val := shr(0xe0, calldataload(offset))
        }
    }

    function slice(uint256 offset, uint256 length) internal pure returns (bytes calldata) {
        assembly {
            calldatacopy(0, offset, length)
            return(0, length)
        }
    }
}
