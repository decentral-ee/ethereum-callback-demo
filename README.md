# ethereum-callback-demo
Usint contracts callback and try/catch in solidity.

# Motivation

A general solidity code pattern to trigger a external contract call and record the contract call error if any. It is key to handle these cases:

- Gas deny of service, the app might want to use inifite amount of gas and block the error recording. (see test "good app flow", "update by limited gas" section)
- Erronuously recording out of gas error: if the app callback could be executed with more gas limit, it should not be recorded as an error (see test "gassy app flow")
- If any app error is cought, the app error should be be recorded.
