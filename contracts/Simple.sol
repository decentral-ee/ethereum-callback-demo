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

    constructor() public {
        a = new A();
    }

    function case1() external {
        //uint256 gasLeft = gasleft();
        try a.doSomething() {
        } catch Error(string memory reason) {
            require(false, reason);
        } catch (bytes memory lowLevelData) {
            // how to reliably know it is due to out of gas
            // instead of other errors?
            // isOutOfGas(lowLevelData)
            /* if (isOutOfGas(lowLevelData)) {
                // ... do not send app to jail
            } */
            require(false, "Low level data caught");
        }
    }

    function case2() external {
        bool caught = false;
        try a.doRevert() {
        } catch {
            caught = true;
        }
        require(caught, "Something should be caught");
    }

    function case3() external {
        uint256 gasBefore = gasleft();
        try a.useAllGas() {
        } catch Error(string memory reason) {
            require(false, reason);
        } catch (bytes memory lowLevelData) {
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
