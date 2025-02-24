const BN = require('bn.js');
const elliptic = require('elliptic');
const keccak = require('keccak');
const crypto = require('crypto');
const uuid = require('uuid');
const readline = require('readline');

// Create ECDSA secp256k1 curve
const ec = new elliptic.ec('secp256k1');

// Generate a new ECDSA keypair
function genKeypair() {
    const key = ec.genKeyPair();
    return key;
}

// Generate a random 32-byte session secret
function genSessionSecret() {
    const secret = new BN(crypto.randomBytes(32));
    return secret;
}

// Hash the message using keccak256 and truncate if necessary
function hashMessage(msg) {
    let hash = new BN(keccak('keccak256').update(msg).digest('hex'), 16);
    const orderLength = ec.curve.n.bitLength(); 
    const hashLength = hash.byteLength() * 8; // in bits
    hash = hash.ushrn(Math.max(0, hashLength - orderLength));
    return hash;
}

// Create readline interface for user input
const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

function prompt(question) {
    return new Promise(resolve => rl.question(question, resolve));
}

// Main execution
(async function() {
    const key = genKeypair();
    const priv = key;
    const pub = ec.keyFromPublic(key.getPublic().encode('hex'), 'hex');
    const sessionSecret = genSessionSecret();

    for (let i = 0; i < 4; i++) {
        const message = await prompt("message? ");
        const hashed = hashMessage(message);
        const sig = priv.sign(hashed, {k: () => sessionSecret});
        console.log(`r=0x${sig.r.toString(16).padStart(64, '0')}`);
        console.log(`s=0x${sig.s.toString(16).padStart(64, '0')}`);
    }

    const test = hashMessage(uuid.v4().replace(/-/g, ''));
    console.log(`test=0x${test.toString(16).padStart(64, '0')}`);

    const r = new BN(await prompt("r? "), 16);
    const s = new BN(await prompt("s? "), 16);

    if (!pub.verify(test, { r, s })) {
        console.log("better luck next time");
        process.exit(1);
    }

    console.log("solved");

    rl.close();
})();
