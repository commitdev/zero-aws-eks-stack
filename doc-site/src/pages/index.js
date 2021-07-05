import React from 'react';
import { Redirect } from 'react-router-dom';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';

export default () => {
  const { siteConfig } = useDocusaurusContext();
  return <Redirect to={`${ siteConfig.baseUrl }about/overview`} />
}
