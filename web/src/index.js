import React from 'react';
import ReactDOM from 'react-dom';
import App from './App';
import queryString from 'query-string'

const query = queryString.parse(location.search)

if (query.bucket) {
  window.BUCKET = query.bucket
} else {
  window.BUCKET = 'songs'
}

ReactDOM.render(
  <App />,
  document.getElementById('root')
);