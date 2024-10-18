const fs = require("fs");
const path = require("path");
function convertCsvToJsList(filePath) {
  const csvContent = fs.readFileSync(filePath, "utf8");

  const lines = csvContent.split("\n");

  lines.shift();

  // converting  each line to an array and filter out any empty lines
  const values = lines
    .filter((line) => line.trim() !== "")
    .map((line) => {
      const [address, index] = line.split(",");
      return [address, index];
    });

  const jsCode = `// defining airdrop list
const values = ${JSON.stringify(values, null, 1)};

module.exports = { values };`;

  return jsCode;
}

const csvFilePath = path.join(__dirname, "addresses.csv");

const jsListCode = convertCsvToJsList(csvFilePath);

console.log(jsListCode);

fs.writeFileSync("airdrop_list.js", jsListCode);
