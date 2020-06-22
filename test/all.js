const Framework = artifacts.require("Framework");
const GoodApp = artifacts.require("GoodApp");
const BadApp = artifacts.require("BadApp");
const GassyApp = artifacts.require("GassyApp");
const { expectRevert } = require("@openzeppelin/test-helpers");
const { web3tx } = require("@decentral.ee/web3-test-helpers");

const convert = (from, to) => str => Buffer.from(str, from).toString(to)
//const utf8ToHex = convert('utf8', 'hex')
const hexToUtf8 = convert('hex', 'utf8')

function bytes32toStr(b) {
    if (b === null) return "";
    if (b.startsWith("0x")) return hexToUtf8(b.slice(2)).replace(/\0/g, "");
    return hexToUtf8(b).replace(/\0/g, "");
}

contract("Test all", (accounts) => {

    const [admin, alice, bob, carol] = accounts;
    let framework;
    let goodApp;
    let badApp;
    let gassyApp;

    before(() => {
        console.log("admin", admin);
        console.log("alice", alice);
        console.log("bob", bob);
        console.log("carol", carol);
    });

    beforeEach(async () => {
        framework = await web3tx(Framework.new, "Framework.new")();
        goodApp = await web3tx(GoodApp.new, "GoodApp.new")();
        badApp = await web3tx(BadApp.new, "BadApp.new")();
        gassyApp = await web3tx(GassyApp.new, "GassyApp.new")();
        console.log("framework", framework.address);
        console.log("goodApp", goodApp.address);
        console.log("badApp", badApp.address);
        console.log("gassyApp", gassyApp.address);
    });

    it("good app flow", async () => {
        // connect alice and bob
        await web3tx(goodApp.connect, "goodApp connect alice and blob, initial value at 3")(
            framework.address, alice, bob, 3, {
                from: admin
            }
        );
        assert.equal(
            (await framework.getValue(alice, "good")).toString(),
            "3"
        );
        assert.equal(
            (await framework.getValue(alice, "good")).toString(),
            (await framework.getValue(bob, "good")).toString()
        );

        // set value by the app (by alice)
        const txGoodAppUpdate = await web3tx(goodApp.update, "goodApp update alice value")(
            framework.address, 4, {
                from: alice
            }
        );
        assert.equal(
            (await framework.getValue(alice, "good")).toString(),
            "4"
        );
        assert.equal(
            (await framework.getValue(alice, "good")).toString(),
            (await framework.getValue(bob, "good")).toString()
        );

        // set value by bob directly
        await web3tx(framework.setValue, "bob update its own box")(
            bob, "good", 5, {
                from: bob
            }
        );
        assert.equal(
            (await framework.getValue(alice, "good")).toString(),
            "5"
        );
        assert.equal(
            (await framework.getValue(alice, "good")).toString(),
            (await framework.getValue(bob, "good")).toString()
        );

        // update by wrong person
        await expectRevert(framework.setValue(bob, "good", 6, { from: alice }), "Unauthorized access to the box");

        // update by limited gas
        await expectRevert.unspecified(goodApp.update(
            framework.address, 8, {
                from: alice,
                gas: txGoodAppUpdate.receipt.gasUsed + 70
            }
        ));
        await web3tx(goodApp.update, "goodApp update alice with limited gas")(
            framework.address, 8, {
                from: alice,
                gas: txGoodAppUpdate.receipt.gasUsed + 71
            }
        );
        assert.equal(
            (await framework.getValue(alice, "good")).toString(),
            "8"
        );
        assert.equal(
            (await framework.getValue(alice, "good")).toString(),
            (await framework.getValue(bob, "good")).toString()
        );
        assert.equal(bytes32toStr(await framework.getAppError(goodApp.address)), "");
    });

    it("bad app flow", async () => {
        await web3tx(badApp.screw, "badApp screws alice")(
            framework.address, alice, {
                from: admin
            }
        );
        assert.equal(
            (await framework.getValue(alice, "bad")).toString(),
            "42"
        );
        // alice should be able to update bad box still
        await web3tx(framework.setValue, "alice updates its own box")(
            alice, "bad", 5, {
                from: alice
            }
        );
        assert.equal(
            (await framework.getValue(alice, "bad")).toString(),
            "5"
        );
        const appError = await framework.getAppError(badApp.address);
        console.log("appError", bytes32toStr(appError));
        assert.equal(
            bytes32toStr(appError),
            "I am a bad app"
        );
    });

    it("gassy app flow", async () => {
        await web3tx(gassyApp.infect, "gassyApp infects alice")(
            framework.address, alice, {
                from: admin
            }
        );
        assert.equal(
            (await framework.getValue(alice, "gassy")).toString(),
            "2020"
        );
        // alice should be able to update bad box still
        await web3tx(framework.setValue, "alice updates its own box")(
            alice, "gassy", 5, {
                from: alice,
                gas: 4000000,
            }
        );
        assert.equal(
            (await framework.getValue(alice, "gassy")).toString(),
            "5"
        );
        const appError = await framework.getAppError(gassyApp.address);
        console.log("appError", bytes32toStr(appError));
        assert.equal(
            bytes32toStr(appError),
            "Unknown low-level error"
        );
    });

});

