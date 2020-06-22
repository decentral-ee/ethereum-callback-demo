// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.6.0;

interface IApp {
    function onValueChanged(Framework i, address owner, string calldata id, uint256 value) external;
}

library StringUtils {

    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function bytesToBytes32(bytes memory source) internal pure returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }

}

contract Framework {
    // Box is a managed uint256 value.
    // When the value is updated by the owner, the app is notified and more changes can be triggered.
    // When the value is updated by an app, the app has exclusive control other than its owners to manage the value.
    struct Box {
        uint256 value;
        IApp app;
        bytes appData;
    }
    mapping (address => mapping(string => Box)) _boxes;
    mapping (address => bytes32) _appErrors;

    //
    // For users
    //

    function getValue(address owner, string calldata id) external view returns (uint256) {
        Box storage box = _boxes[owner][id];
        return box.value;
    }

    function setValue(address owner, string calldata id, uint256 value) external {
        Box storage box = _boxes[owner][id];
        box.value = value;

        if (msg.sender != owner) {
            // if sender is not the owner, it is an app,  and the app should do the full updates
            if (address(box.app) == address(0)) {
                box.app = IApp(msg.sender);
            }
            require(address(box.app) == msg.sender, "Unauthorized access to the box");
        } else {
            // if the sender is the owner, and there is an app registered, notify the app
            if (address(box.app) != address(0)) {
                uint256 gasLeft = gasleft();
                try box.app.onValueChanged{gas: gasLeft - 10000}(this, owner, id, value) {
                    // all good
                } catch Error(string memory reason) {
                    _appErrors[address(box.app)] = StringUtils.stringToBytes32(reason);
                    return;
                } catch (bytes memory lowLevelData) {
                    if (lowLevelData.length == 0) {
                        _appErrors[address(box.app)] = StringUtils.stringToBytes32("Unknown low-level error");
                    } else {
                        _appErrors[address(box.app)] = StringUtils.bytesToBytes32(lowLevelData);
                    }
                    return;
                }
            }
        }
    }

    //
    // For apps
    //
    function getAppData(address owner, string calldata id) external view returns (bytes memory) {
        Box storage box = _boxes[owner][id];
        return box.appData;
    }

    function setAppData(address owner, string calldata id, bytes calldata data) external {
        Box storage box = _boxes[owner][id];
        require(address(box.app) == msg.sender, "Not authorized app");
        box.appData = data;
    }

    function getAppError(address app) external view returns (bytes32) {
        return _appErrors[app];
    }

}

contract GoodApp is IApp {

    string constant BOX_ID = "good";

    function connect(Framework i, address a, address b, uint256 value) external {
        i.setValue(a, BOX_ID, value);
        i.setValue(b, BOX_ID, value);
        i.setAppData(a, BOX_ID, abi.encode(b));
        i.setAppData(b, BOX_ID, abi.encode(a));
    }

    function update(Framework i, uint256 value) external {
        bytes memory data = i.getAppData(msg.sender, BOX_ID);
        address other = abi.decode(data, (address));
        i.setValue(msg.sender, BOX_ID, value);
        i.setValue(other, BOX_ID, value);
    }

    function onValueChanged(Framework i, address owner, string calldata id, uint256 value) external override {
        require(keccak256(abi.encodePacked(id)) == keccak256(abi.encodePacked(BOX_ID)));
        bytes memory data = i.getAppData(owner, id);
        address other = abi.decode(data, (address));
        i.setValue(other, BOX_ID, value);
    }

}

contract BadApp is IApp {

    string constant BOX_ID = "bad";

    function screw(Framework i, address a) external {
        i.setValue(a, BOX_ID, 42);
    }

    function onValueChanged(Framework, address, string calldata, uint256) external override{
        revert("I am a bad app");
    }

}

contract GassyApp is IApp {

    string constant BOX_ID = "gassy";
    uint256[] intestant;

    function infect(Framework i, address a) external {
        i.setValue(a, BOX_ID, 2020);
    }

    function onValueChanged(Framework, address, string calldata, uint256) external override{
        // make an infinite fart
        while (true) intestant.push(20);
    }

}

