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
        await web3tx(tester.case1, "tester.case1 pass 1")();
        await web3tx(tester.case1, "tester.case1 pass 2")();
        const tx = await web3tx(tester.case1, "tester.case1 pass 3")();
        await web3tx(tester.case1, "tester.case1 - with less gas")({
            gas: tx.receipt.gasUsed
        });
    });

    it("case2 - catch normal errors", async () => {
        await web3tx(tester.case2, "tester.case2")();
    });

    it("case3 - catch DoS by inducing out of gas", async () => {
        let tx = await web3tx(tester.case3, "tester.case3")();
        console.log("tx !!!!", wad4human(tx.logs[0].args.amount), tx.logs[0].args.amount);
    });

    it.only("case3 and case 4 some magic", async () => {
        let tx1 = await web3tx(tester.case4, "tester.case4")();
        console.log("gas cost1", tx1.logs[0].args.amount.toString());
        let tx2 = await web3tx(tester.case5, "tester.case5")();
        console.log("gas cost2", tx2.logs[0].args.amount.toString());
    });

    it.only("case3 - catch DoS by inducing out of gas", async () => {
    });

});
