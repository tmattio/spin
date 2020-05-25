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
  path.join(src, "scripts", "release-postinstall.js"),
  path.join(dst, "postinstall.js")
);

const filesToTouch = [
  "{{ project_slug }}"
];

for (const file of filesToTouch) {
  const p = path.join(dst, file);
  mkdirpSync(path.dirname(p));
  fs.writeFileSync(p, "");
}

const pkgJson = {
  name: "@{{ npm_username }}/{{ project_slug }}",
  version: "%%{% raw %}VERSION{% endraw %}%%",
  description: "{{ project_description }}",
  author: "{{ username }}{% if author_email %} <{{ author_email }}>{% endif %}",
  license: "MIT",
  homepage: "https://github.com/{{ github_username }}/{{ project_slug }}",
  bugs: {
    url: "https://github.com/{{ github_username }}/{{ project_slug }}/issues"
  },
  repository: {
    type: "git",
    url: "https://github.com/{{ github_username }}/{{ project_slug }}.git"
  },
  scripts: {
    postinstall: "node postinstall.js"
  },
  bin: {
    {{ project_slug }}: "{{ project_slug }}"
  },
  files: [
    "platform-windows-x64/",
    "platform-linux-x64/",
    "platform-darwin-x64/",
    "postinstall.js",
    "{{ project_slug }}"
  ]
};

fs.writeFileSync(path.join(dst, "package.json"), JSON.stringify(pkgJson, null, 2));
