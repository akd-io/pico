/*
  For every picotron dir in the `out` dir:
  - Run `picotron -x print-env.lua` and save the output to a file in a new `builtins/<version>` dir.

  !NOTE: The `-x` CLI argument was first introduced in Picotron v0.1.1, so prior versions will not run the script.
*/

import { $ } from "bun";
import path from "path";

import { mkdir, readdir } from "node:fs/promises";

const outDir = path.resolve(import.meta.dir, "out");
const dirContents = await readdir(outDir);

const folders = dirContents.filter(async (fileName) => {
  const filePath = path.resolve(outDir, fileName);
  let isDir = false;
  try {
    await readdir(fileName);
    isDir = true;
  } catch {
    console.log("Not a directory: ", fileName);
    /* handle error if you want */
  }
  return isDir;
});

$.cwd(import.meta.dir);

// TODO: Exclude versions prior to v.0.1.1, since they don't support the `-x` CLI argument.
// TODO: Or, instead for old versions, output a TODO.md file with a TODO comment describing what code to run.
for (const folderName of folders) {
  const folderPath = path.resolve(outDir, folderName);

  const picotronBinaryDirPath = path.resolve(
    folderPath,
    "picotron",
    "Picotron.app",
    "Contents",
    "MacOS"
  );
  const picotronBinaryPath = path.resolve(picotronBinaryDirPath, "picotron");

  if (!Bun.file(picotronBinaryPath).exists()) {
    console.log("Picotron binary not found in ", folderPath);
    continue;
  }

  console.log("Running in ", folderName);
  let output = null;
  try {
    output = await $`${picotronBinaryPath} -x print-env.lua`; // TODO: Time out after 3 seconds, so we don't have to close the window for every version not supporting -x?
  } catch (err) {
    console.log("Error running picotron: ", err);
    continue;
  }
  console.log("Got output of size: ", output.text().length);
  mkdir(path.resolve(import.meta.dir, "envs"), { recursive: true });
  await Bun.write(
    path.resolve(import.meta.dir, "envs", `${folderName}.txt`),
    output.text()
  );
}
