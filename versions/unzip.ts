import { $ } from "bun";
import path from "path";

import { mkdir, readdir } from "node:fs/promises";

const outDir = path.resolve(import.meta.dir, "out");
const fileNames = await readdir(outDir);
const zipFileNames = fileNames.filter((fileName) => fileName.endsWith(".zip"));

for (const zipFileName of zipFileNames) {
  const zipFilePath = path.resolve(import.meta.dir, "out", zipFileName);
  const destinationPath = path.resolve(
    import.meta.dir,
    "out",
    zipFileName.replace(".zip", "")
  );
  console.log(`Unzipping ${zipFileName} to ${destinationPath}`);
  await mkdir(destinationPath, { recursive: true });
  await $`unzip -o ${zipFilePath} -d ${destinationPath}`;
}
