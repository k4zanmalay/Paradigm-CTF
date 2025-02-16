const { ethers } = require("hardhat");
const crypto = require("crypto");

// Generate an ECDSA keypair
async function genKeypair() {
    const wallet = ethers.Wallet.createRandom();
    return {
        priv: wallet.privateKey,
        pub: wallet.publicKey
    };
}

// Generate a random 32-byte session secret
function genSessionSecret() {
    return BigInt("0x" + crypto.randomBytes(32).toString("hex"));
}

// Hash the message using keccak256
function hashMessage(msg) {
    return BigInt(ethers.utils.keccak256(ethers.utils.toUtf8Bytes(msg)));
}

async function main() {
    const flag = process.env.FLAG || "PCTF{placeholder}";

    const { priv, pub } = await genKeypair();
    const wallet = new ethers.Wallet(priv);
    const sessionSecret = genSessionSecret();

    for (let i = 0; i < 4; i++) {
        process.stdout.write("message? ");
        const message = await readInput();
        const hashed = hashMessage(message);

        const signature = await wallet.signMessage(ethers.utils.arrayify(hashed));
        const { r, s } = ethers.utils.splitSignature(signature);

        console.log(`r=0x${r.slice(2)}`);
        console.log(`s=0x${s.slice(2)}`);
    }

    const test = hashMessage(crypto.randomUUID());
    console.log(`test=0x${test.toString(16).padStart(64, "0")}`);

    process.stdout.write("r? ");
    const r = "0x" + (await readInput());

    process.stdout.write("s? ");
    const s = "0x" + (await readInput());

    const recoveredPub = ethers.utils.recoverPublicKey(ethers.utils.arrayify(test), { r, s, v: 27 });

    if (recoveredPub.toLowerCase() !== pub.toLowerCase()) {
        console.log("better luck next time");
        process.exit(1);
    }

    console.log(flag);
}

// Function to read user input
function readInput() {
    return new Promise(resolve => {
        process.stdin.once("data", data => resolve(data.toString().trim()));
    });
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
