// @flow

const { execSync } = require("child_process");
const fs = require("fs");
const path = require("path");

const filesToCopy = ["LICENSE", "README.md", "CHANGES.md"];

function exec(cmd) {
  console.log(`exec: ${cmd}`);
  return execSync(cmd).toString();
}

function mkdirpSync(p) {
  if (fs.existsSync(p)) {
    return;
  }
  mkdirpSync(path.dirname(p));
  fs.mkdirSync(p);
}

function removeSync(p) {
  exec(`rm -rf "${p}"`);
}

const src = path.resolve(path.join(__dirname, ".."));
const dst = path.resolve(path.join(__dirname, "..", "_release"));

removeSync(dst);
mkdirpSync(dst);

for (const file of filesToCopy) {
  const p = path.join(dst, file);
  mkdirpSync(path.dirname(p));
  fs.copyFileSync(path.join(src, file), p);
}

fs.copyFileSync(
  path.join(src, "script", "release-postinstall.js"),
  path.join(dst, "postinstall.js")
);

const filesToTouch = [
  "spin"
];

for (const file of filesToTouch) {
  const p = path.join(dst, file);
  mkdirpSync(path.dirname(p));
  fs.writeFileSync(p, "");
}

const pkgJson = {
  name: "@tmattio/spin",
  version: "%%VERSION%%",
  description: "Reason and OCaml project generator.",
  author: "Thibaut Mattio",
  homepage: "https://github.com/tmattio/spin",
  license: "MIT",
  repository: {
    type: "git",
    url: "https://github.com/tmattio/spin.git"
  },
  scripts: {
    postinstall: "node postinstall.js"
  },
  bin: {
    spin: "spin"
  },
  files: [
    "platform-linux-x64/",
    "platform-darwin-x64/",
    "postinstall.js",
    "spin"
  ]
};

fs.writeFileSync(path.join(dst, "package.json"), JSON.stringify(pkgJson, null, 2));
