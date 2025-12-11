const { execFileSync } = require("child_process");
const path = require("path");
const os = require("os");

function main() {
  console.log("[expose-ip-package] postinstall started.");

  if (os.platform() !== "win32") {
    console.warn("[expose-ip-package] Skipping BAT execution: not on Windows.");
    return;
  }

  const batPath = path.join(__dirname, "setup-env.bat");

  try {
    execFileSync("cmd.exe", ["/c", batPath], {
      stdio: "inherit"
    });
    console.log("[expose-ip-package] BAT script executed successfully.");
  } catch (err) {
    console.error("[expose-ip-package] Error running BAT script:", err.message);
    process.exit(1);
  }
}

main();