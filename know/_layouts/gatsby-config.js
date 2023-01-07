module.exports = {
    siteMetadata: {
      title: `know`,
      siteUrl: `https://know.kalebpace.me`
    },
    plugins: [
      {
        resolve: `gatsby-philipps-foam-theme`,
        options: {
          basePath: `/`,
          contentPath: `${__dirname}/../content`,
          rootNote: `home`,
          ignore: [
            "**/_private/**/*",
          ],
        },
      },
    ],
  };