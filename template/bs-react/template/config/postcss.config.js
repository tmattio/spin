const path = require("path");
const glob = require("glob");

const purgecss = require("@fullhuman/postcss-purgecss")({
    content: ["public/index.html", ...glob.sync("src/**/*", { nodir: true })],
    defaultExtractor: content => content.match(/[A-Za-z0-9-_:/]+/g) || []
})

module.exports = {
    plugins: [
        require("tailwindcss")(path.join(__dirname, "tailwind.config.js")),
        require("autoprefixer"),
        ...process.env.NODE_ENV === "production"
            ? [purgecss]
            : [],
        require("postcss-preset-env")({
            autoprefixer: {
                flexbox: "no-2009",
            },
            stage: 3,
        }),
    ]
}