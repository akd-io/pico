import { $ } from "bun";
import path from "path";

const versions = [
  "0.1.0",
  "0.1.0b",
  "0.1.0c",
  "0.1.0d",
  "0.1.0e",
  "0.1.0f",
  "0.1.0g",
  "0.1.0h",
  "0.1.1",
  "0.1.1b",
  "0.1.1c",
  "0.1.1d",
  "0.1.1e",
  "0.1.1f",
  "0.2.0",
  "0.2.0b",
  "0.2.0c",
];

for (const version of versions) {
  const fileName = `picotron_${version}_osx.zip`;
  const outPath = path.resolve(__dirname, "out", fileName);
  const outFile = Bun.file(outPath);

  if (await outFile.exists()) {
    console.log(`Skipping ${fileName}`);
    continue;
  }

  const response = await fetch(`${process.env.prefix}${fileName}`);
  const buffer = await response.arrayBuffer();
  await Bun.write(outFile, buffer);
  console.log(`Downloaded ${fileName}`);
}
