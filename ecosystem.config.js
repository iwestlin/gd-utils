module.exports = {
  apps : [{
    name: "gd-utils",
    script: "./server.js",
    exec_mode: "fork",
    watch: "true",
    ignore_watch: ["gdurl.sqlite", "node_modules", "backup", "sa/invalid"],
    env: {
      NODE_ENV: "development",
    },
    env_production: {
      NODE_ENV: "production",
    }
  }]
}
