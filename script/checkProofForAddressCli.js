const readline = require("readline/promises");
const { generateProof } = require("./createMerkleProof");

async function main() {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  try {
    const address = await rl.question("Input address to check proof ");
    const proof = generateProof(address);
    console.log(proof);
  } catch (error) {
    console.error("An error occurred:", error);
  } finally {
    rl.close();
  }
}

main().catch((error) => console.error("Unhandled error:", error));
