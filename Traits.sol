// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IXEN.sol";

// 0x607Ac42C499CfC58C5ba0C71AacdF6d8554b303b
contract Traits {
    using Strings for uint256;
    using Strings for address;

    constructor() {
    }

    function tokenURI(
        uint256 tokenId,
        uint256 peroidIndex,
        uint256 burnedAmount      
    ) public pure returns (string memory) {        
        string memory metadata = string(
            abi.encodePacked(
                '{"name": "DNFT #',
                tokenId.toString(),
                '", "description": "DNFT is an NFT that contains the information of burned XEN and can mint dividends which comes from the minted fee of XEN.", "image": "data:image/svg+xml;base64,',
                base64(bytes(drawSVG(peroidIndex, burnedAmount))),
                '", "attributes":',
                compileAttributes(peroidIndex, burnedAmount),
                "}"
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    base64(bytes(metadata))
                )
            );
    }

    function drawSVG(
        uint256 peroidIndex,
        uint256 burnedAmount
    ) public pure returns (string memory) {        
        string[13] memory parts;
        uint256 i = 0;
        parts[i++] = '<svg width="300px" height="300px" viewBox="-5 0 55 55" id="svg5" version="1.1" xml:space="preserve"  xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg">';
        parts[i++] = '<style>.base { fill:#fcca3d; font-family: serif; font-size: 4px; }</style>';
        parts[i++] = '<style>.base1 { fill:#e7e7e7;fill-opacity:1;fill-rule:evenodd;stroke:none;stroke-width:2;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:4.1 }</style>';
        parts[i++] = '<style>.base2 { fill:#fafafa;fill-opacity:1;fill-rule:evenodd;stroke:none;stroke-width:2;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:4.1 }</style>';
        // parts[i++] = '<rect width="100%" height="100%" fill="black" />';
        parts[i++] = '<g transform="translate(-314.00003,-449)"><path d="m 319,463.48769 19,-10 19,10 z" id="rect24147" class="base1"/><path d="M 331.48047,456.91933 319,463.48769 h 27.64648 a 21.191124,12.336339 0 0 0 -15.16601,-6.56836 z" id="ellipse84876" class="base2"/><path d="m 319,463.48769 h 38 v 4 h -38 z" id="rect24150" class="base1"/><path d="m 319,463.48769 v 4 h 29.76172 a 21.191124,12.336339 0 0 0 -2.11524,-4 z" id="path84874" class="base2"/><path d="m 319,486.48769 h 38 v 6 h -38 z" id="rect24152" class="base1"/><path d="m 319,486.48769 v 3.16992 h 30.70312 a 3.68215,3.68215 0 0 0 3.60157,-3.16992 z" id="path88205" style="fill:#fafafa;fill-opacity:1;fill-rule:evenodd;stroke-width:2;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:4.1"/></g>';
        parts[i++] = '<g transform="scale(0.08,0.18) translate(145,87)"><path id="x" d="M114.31 117.18L81.14 68.9l33-49.02c.48-.73.54-1.66.12-2.43a2.357 2.357 0 0 0-2.08-1.25H84.33c-.78 0-1.51.38-1.95 1.03L64 43.97L45.62 17.22a2.373 2.373 0 0 0-1.95-1.03H15.83c-.87 0-1.68.48-2.08 1.25c-.42.77-.36 1.71.12 2.43L46.86 68.9l-33.17 48.28c-.49.72-.55 1.66-.14 2.44c.41.77 1.22 1.26 2.09 1.26H44.9c.79 0 1.52-.39 1.96-1.04L64 94.36l17.15 25.48c.44.65 1.17 1.04 1.96 1.04h29.25c.88 0 1.68-.49 2.1-1.26c.4-.78.35-1.72-.15-2.44z" fill="#fdda4d"/></g>';
        parts[i++] = '<g transform="scale(0.08,0.18) translate(325,87)"><use href="#x"/></g><g transform="translate(-314.00003,-449)"><ellipse id="dot" cx="338" cy="459.4877" rx="0.93075401" ry="0.92241609" style="fill:#ff5576;fill-opacity:1;fill-rule:evenodd;stroke:none;stroke-width:2;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:4.1"/></g><g transform="translate(-311.00003,-449)"><use href="#dot"/></g><g transform="translate(-317.00003,-449)"><use href="#dot"/></g><g transform="translate(-314.00003,-449)"><path id="path24171" d="m 333.99991,467.48769 h 8 l -2,3 v 12.98819 l 2,3.01181 h -8 l 2,-3.01401 v -12.98599 z" style="fill:#fcca3d;fill-opacity:1;fill-rule:evenodd;stroke:none;stroke-width:2;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:4.1"/></g>';
        parts[i++] = '<g transform="translate(-300.00003,-449)"><use href="#path24171"/></g><g transform="translate(-328.00003,-449)"><use href="#path24171"/></g>';
        parts[i++] = '<text x="5" y="48" class="base">';

        // total reward:
        parts[i++] = string(
            abi.encodePacked("Mintable Peroid: ", peroidIndex.toString())
        );

        parts[i++] = '</text><text x="5" y="53" class="base">';

        // percent of this NFT
        parts[i++] = string(
            abi.encodePacked(
                "Burned XEN: ",
                (burnedAmount / 10**18).toString()
            )
        );

        parts[i++] = "</text></svg>";

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7]));
        output = string(abi.encodePacked(output, parts[8], parts[9], parts[10], parts[11], parts[12]));

        return output;
    }

    function attributeForTypeAndValue(
        string memory traitType,
        string memory value
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"',
                    traitType,
                    '","value":"',
                    value,
                    '"}'
                )
            );
    }

    function compileAttributes(
        uint256 peroidIndex,
        uint256 burnedAmount  
    ) public pure returns (string memory) {
        string memory traits = string(
            abi.encodePacked(
                attributeForTypeAndValue(
                    "MintablePeroid",
                    peroidIndex.toString()
                ),
                ",",
                attributeForTypeAndValue(
                    "Burned XEN",
                    (burnedAmount / 10**18).toString()
                )
            )
        );

        return string(abi.encodePacked("[", traits, "]"));
    }

    /** BASE 64 - Written by Brech Devos */
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function base64(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}
