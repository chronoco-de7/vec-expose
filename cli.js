#!/usr/bin/env node
const path = require("path");
const { execFileSync } = require("child_process");
const os = require("os");

function main() {
  console.log("[expose-ip-package] expose-ip CLI started.");

  if (os.platform() !== "win32") {
    console.warn("[expose-ip-package] This tool currently supports Windows only.");
    process.exit(0);
  }

  const batPath = path.join(__dirname, "setup-env.bat");

  try {
    execFileSync("cmd.exe", ["/c", batPath], {
      stdio: "inherit"
    });
  } catch (err) {
    console.error("[expose-ip-package] Error executing BAT from CLI:", err.message);
    process.exit(1);
  }
}

main();