// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.6.0;

contract A {
    uint256[] intestant;
    mapping (uint => uint256) stomach;

    function doSomething() external {
        intestant.push(1);
    }

    function doRevert() external {
        intestant.push(2);
        revert("I am broken");
    }

    function doEmptyRevert() external {
        intestant.push(2);
        revert();
    }

    function doAssert() external {
        intestant.push(2);
        assert(false);
    }

    function doDivideByZero() external {
        uint a = uint(1) / uint(0);
    }

    function useAllGas() external {
        while (true) intestant.push(3);
    }

    function allocateSome(uint n) external {
        while (n > 0) {
            stomach[n] = n;
            --n;
        }
    }

    function freeSome(uint n) external {
        while (n > 0) {
            stomach[n] = 0;
            --n;
        }
    }

    function freeOps(uint n) external {
        while (n > 0) --n;
    }
}

contract SimpleTester {
    A a;

    uint256 constant GAS_RESERVATION = 10000;

    event Result(string result, bytes reason, uint256 gasLeft);

    constructor() public {
        a = new A();
    }

    function _callCallback(bytes memory data) private {
        uint256 gasLeft = gasleft();
        uint256 gasBudget = gasLeft - GAS_RESERVATION;
        (bool success, bytes memory returnedData) =
            address(a).call{gas: gasBudget}(data);
        if (success) {
            emit Result("success", "", gasleft());
        } else {
            gasLeft = gasleft();
            emit Result("revert1", returnedData, gasleft());
            if (gasLeft < GAS_RESERVATION) {
                // this is out of gas, but the call may still fail if more gas is provied
                // and this is okay, because there can be incentive to jail the app by providing
                // more gas
            } else {
                // go to jail
            }
        }
    }

    function case1_v1() external {
        uint256 gasLeft = gasleft();
        try a.doSomething{gas: gasLeft - GAS_RESERVATION}() {
        } catch Error(string memory reason) {
            require(false, reason);
        } catch (bytes memory lowLevelData) {
            // how to reliably know it is due to out of gas
            // instead of other errors?
            // isOutOfGas(lowLevelData)
            /* if (isOutOfGas(lowLevelData)) {
                // ... do not send app to jail
            } */
            emit Result("revert2", lowLevelData, gasleft());
            return;
        }
        emit Result("success", "", gasleft());
    }

    function case1() external {
        _callCallback(abi.encodeWithSelector(A.doSomething.selector));
    }

    function case2_Revert() external {
        _callCallback(abi.encodeWithSelector(A.doRevert.selector));
        /* uint256 gasLeft = gasleft();
        try a.doRevert{gas: gasLeft - GAS_RESERVATION}() {
        } catch Error(string memory reason) {
            emit Result("revert1", bytes(reason), gasleft());
            return;
        } catch (bytes memory lowLevelData) {
        emit Result("revert2", lowLevelData, gasleft());
            return;
        }
        revert("Something should be caught"); */
    }

    function case2_EmptyRevert() external {
        _callCallback(abi.encodeWithSelector(A.doEmptyRevert.selector));
        /* uint256 gasLeft = gasleft();
        try a.doEmptyRevert{gas: gasLeft - GAS_RESERVATION}() {
        }  catch Error(string memory reason) {
            emit Result("revert1", bytes(reason), gasleft());
            return;
        } catch (bytes memory lowLevelData) {
        emit Result("revert2", lowLevelData, gasleft());
            return;
        }
        revert("Something should be caught"); */
    }

    function case2_Assert() external {
        _callCallback(abi.encodeWithSelector(A.doAssert.selector));
        /* uint256 gasLeft = gasleft();
        try a.doAssert{gas: gasLeft - GAS_RESERVATION}() {
        }  catch Error(string memory reason) {
            emit Result("revert1", bytes(reason), gasleft());
            return;
        } catch (bytes memory lowLevelData) {
        emit Result("revert2", lowLevelData, gasleft());
            return;
        }
        revert("Something should be caught"); */
    }

    function case2_DivideByZero() external {
        _callCallback(abi.encodeWithSelector(A.doDivideByZero.selector));
        /* uint256 gasLeft = gasleft();
        try a.doDivideByZero{gas: gasLeft - GAS_RESERVATION}() {
        }  catch Error(string memory reason) {
            emit Result("revert1", bytes(reason), gasleft());
            return;
        } catch (bytes memory lowLevelData) {
        emit Result("revert2", lowLevelData, gasleft());
            return;
        }
        revert("Something should be caught"); */
    }

    function case3() external {
        uint256 gasBefore = gasleft();
        try a.useAllGas() {
        } catch Error(string memory reason) {
            require(false, reason);
        } catch (bytes memory) {
            /* if (isOutOfGas(lowLevelData)) {
                // ... do not send app to jail
            } */
            //require(false, "Should not catch DoS");
        }
        uint256 gasAfter = gasleft();
        uint256 costByApp = (gasBefore - gasAfter) * tx.gasprice;
        emit AppCost(costByApp);
    }
    
    function case4() external {
        uint256 gasBefore = gasleft();
        a.allocateSome(300);
        uint256 gasAfter = gasleft();
        emit GasCost(gasBefore - gasAfter);
    }
    
    function case5() external {
        uint256 gasBefore = gasleft();
        a.freeOps(20000);
        a.freeSome(300);
        //a.allocateSome(100);
        uint256 gasAfter = gasleft();
        emit GasCost(gasBefore - gasAfter);
    }

    event AppCost(uint256 amount);
    event GasCost(uint256 amount);
}
