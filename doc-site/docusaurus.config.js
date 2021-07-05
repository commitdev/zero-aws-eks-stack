/** @type {import('@docusaurus/types').DocusaurusConfig} */
const child_process = require('child_process');

const remoteCommonCssFile = 'https://raw.githubusercontent.com/commitdev/zero/doc-site/doc-site/src/css/custom.css';
const cssDownloadPath = './src/css/zero-downloaded-global-custom.css';

function downloadCss(url, saveTo) {
  child_process.execFileSync('curl', ['--silent', '-f', '-L', url, '-o', saveTo], {encoding: 'utf8'});
  return require.resolve(saveTo);
}

// This is to download the CSS from commitdev/zero instead of using the local copy, this
// allows us to maintain only one set of global css throughout the modules and have
// consistent look and feel throughout the modules, this is synchronous but only runs during build time
let customCss;
try {
  customCss = downloadCss(remoteCommonCssFile, cssDownloadPath)
} catch (e) {
  customCss = require.resolve('./src/css/fallback.css');
}

const siteUrl = process.env.BUILD_DOMAIN ? `https://${process.env.BUILD_DOMAIN}` : 'https://staging.getzero.dev';
const baseUrl = '/docs/modules/aws-eks-stack/';

module.exports = {
  title: 'Zero - AWS EKS Stack Documentation',
  tagline: 'Opinionated infrastructure to take you from idea to production on day one',
  url: siteUrl,
  baseUrl: baseUrl,
  onBrokenLinks: 'warn',
  onBrokenMarkdownLinks: 'warn',
  favicon: 'img/favicon.ico',
  organizationName: 'commitdev',
  projectName: 'zero-aws-eks-stack',
  themeConfig: {
    colorMode: {
      defaultMode: 'dark',
    },
    navbar: {
      logo: {
        alt: 'Zero Logo',
        src: 'img/zero.svg',
      },
      items: [
        {
          href: `${siteUrl}/docs`,
          label: 'Docs',
          className: 'header-docs-link header-logo-24',
          position: 'right'
        },
        {
          href: 'https://slack.getzero.dev',
          label: 'Slack',
          className: 'header-slack-link header-logo-24',
          position: 'right',
        },
        {
          href: 'https://github.com/commitdev/zero',
          label: 'Github',
          className: 'header-github-link header-logo-24',
          position: 'right',
        },
      ],
    },
    footer: {
      links: [
        {
          items: [
            {
              href: `${siteUrl}/docs`,
              label: 'Docs',
              className: 'header-docs-link header-logo-24',
              position: 'right'
            },
            {
              href: 'https://slack.getzero.dev',
              label: 'Slack',
              className: 'header-slack-link header-logo-24',
              position: 'right',
            },
            {
              href: 'https://github.com/commitdev/zero',
              label: 'Github',
              className: 'header-github-link header-logo-24',
              position: 'right',
            },
          ],
        },
      ],
    },
  },
  presets: [
    [
      '@docusaurus/preset-classic',
      {
        docs :{
          sidebarPath: require.resolve('./sidebars.js'),
          path: 'docs',
          routeBasePath: '/',
          editUrl: 'https://github.com/commitdev/zero-aws-eks-stack/blob/main/doc-site/',
        },
        theme: {
          customCss,
        },
        debug: true,
      },
    ],
  ],
  stylesheets: [
    "https://fonts.googleapis.com/css2?family=Lato:wght@400;700;900&family=Montserrat:wght@400;600;700;800&display=swap",
  ]
};
