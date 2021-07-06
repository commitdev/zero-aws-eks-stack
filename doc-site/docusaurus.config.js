/** @type {import('@docusaurus/types').DocusaurusConfig} */
const { downloadCommonCustomCss, themeConfig, stylesheets, misc } = require('@commitdev/zero-doc-site-common-elements');

const siteUrl = process.env.BUILD_DOMAIN ? `https://${process.env.BUILD_DOMAIN}` : 'https://staging.getzero.dev';
const baseUrl = '/docs/modules/aws-eks-stack/';
const repositoryName = 'zero-aws-eks-stack';

let customCss;
try {
  customCss = require.resolve(downloadCommonCustomCss());
} catch (e) {
  console.error("Failing back to local css, if you see this warning means your module theme is likely outdated")
  customCss = require.resolve('./src/css/fallback.css');
}

module.exports = {
  title: 'Zero - AWS EKS Stack Documentation',
  tagline: 'Opinionated infrastructure to take you from idea to production on day one',
  ...misc(), //includes onBrokenLinks, onBrokenMarkdownLinks, favicon, organizationName
  url: siteUrl,
  baseUrl: baseUrl,
  projectName: repositoryName,
  themeConfig: themeConfig({ siteUrl, repositoryName }),
  presets: [
    [
      '@docusaurus/preset-classic',
      {
        docs :{
          sidebarPath: require.resolve('./sidebars.js'),
          path: 'docs',
          routeBasePath: '/',
          editUrl: `https://github.com/commitdev/${repositoryName}/blob/main/doc-site/`,
        },
        theme: {
          customCss,
        },
        debug: true,
      },
    ],
  ],
  stylesheets: stylesheets(),

};
