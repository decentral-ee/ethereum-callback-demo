const SimpleTester = artifacts.require("SimpleTester");
const { expectRevert } = require("@openzeppelin/test-helpers");
const { web3tx, wad4human } = require("@decentral.ee/web3-test-helpers");

contract("Test simple", (accounts) => {

    let tester;
    
    beforeEach(async () => {
        tester = await web3tx(SimpleTester.new, "SimpleTester.new")();
    })

    it("case1 - happy case", async () => {
        await web3tx(tester.case1, "tester.case1")();
    });

    it("case1 - normal gas limit should not be treated as errors", async () => {
        let tx;
        let gasEstimation;

        tx = await web3tx(tester.case1, "tester.case1 pass 1")();
        assert.equal(tx.logs[0].event, "Result");
        assert.equal(tx.logs[0].args.result, "success");
        assert.equal(tx.logs[0].args.reason, null);

        tx = await web3tx(tester.case1, "tester.case1 pass 2")();
        assert.equal(tx.logs[0].args.result, "success");
        assert.equal(tx.logs[0].args.reason, null);

        tx = await web3tx(tester.case1, "tester.case1 pass 3")();
        assert.equal(tx.logs[0].args.result, "success");
        assert.equal(tx.logs[0].args.reason, null);

        gasEstimation = await tester.case1.estimateGas();
        console.log("gas used by last tx", tx.receipt.gasUsed);
        console.log("gasEstimation", gasEstimation);
        tx = await web3tx(tester.case1, "tester.case1 - with less gas")({
            gas: tx.receipt.gasUsed
        });
        assert.equal(tx.logs[0].args.gasLeft.toString(), "7454");
        assert.equal(tx.logs[0].args.reason, null);
        assert.equal(tx.logs[0].args.result, "revert2");
    });

    it("case2 - catch errors", async () => {
        let tx;

        tx = await web3tx(tester.case2_EmptyRevert, "tester.case2_Revert")();
        assert.equal(tx.logs[0].args.result, "revert1");
        assert.equal(tx.logs[0].args.reason, "0x" + new Buffer("I am broken").toString("hex"));

        tx = await web3tx(tester.case2_Revert, "tester.case2_Revert - with less gas")({
            gas: tx.receipt.gasUsed - 5000
        });
        assert.equal(tx.logs[0].args.reason, null);
        assert.equal(tx.logs[0].args.result, "revert2");

        tx = await web3tx(tester.case2_DivideByZero, "tester.doDivideByZero")();
        assert.equal(tx.logs[0].args.reason, null);
        assert.equal(tx.logs[0].args.result, "revert1");
        tx = await web3tx(tester.case2_DivideByZero, "tester.doDivideByZero - with less gas")({
            gas: tx.receipt.gasUsed - 5000
        });
        assert.equal(tx.logs[0].args.result, "revert2");
        assert.equal(tx.logs[0].args.reason, "");
    });

    it.only("gas usage printouts", async () => {
        let tx;
        const printTx = (tx) => {
            console.log(tx.logs[0].args.result, tx.logs[0].args.reason, tx.logs[0].args.gasLeft.toString());
            console.log("=".repeat(80));
        }

        tx = await web3tx(tester.case1, "tester.case1 pass1")();
        printTx(tx);
        tx = await web3tx(tester.case1, "tester.case1 pass2")();
        printTx(tx);
        tx = await web3tx(tester.case1, "tester.case1 pass3 limited gas")({ gas: tx.receipt.gasUsed });
        printTx(tx);

        tx = await web3tx(tester.case2_Revert, "tester.case2_Revert pass1")();
        printTx(tx);

        tx = await web3tx(tester.case2_EmptyRevert, "tester.case2_EmptyRevert pass1")();
        printTx(tx);
        tx = await web3tx(tester.case2_EmptyRevert, "tester.case2_EmptyRevert pass2 limited gas")({ gas: tx.receipt.gasUsed });
        printTx(tx);

        tx = await web3tx(tester.case2_Assert, "tester.case2_EmptyRevert")();
        printTx(tx);

        tx = await web3tx(tester.case2_DivideByZero, "tester.case2_DivideByZero")();
        printTx(tx);
    })

    it("case3 - catch DoS by inducing out of gas", async () => {
        let tx = await web3tx(tester.case3, "tester.case3")();
        console.log("tx", wad4human(tx.logs[0].args.amount), tx.logs[0].args.amount);
    });

    it("case3 and case 4 some magic", async () => {
        let tx1 = await web3tx(tester.case4, "tester.case4")();
        console.log("gas cost1", tx1.logs[0].args.amount.toString());
        let tx2 = await web3tx(tester.case5, "tester.case5")();
        console.log("gas cost2", tx2.logs[0].args.amount.toString());
    });

    it.only("case3 - catch DoS by inducing out of gas", async () => {
    });

});
