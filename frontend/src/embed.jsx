import React from 'react';
import ReactDOM from 'react-dom/client';
import WidgetContainer from './components/WidgetContainer';
import './index.css';

(function mountAskUniWidget() {
  if (typeof document === 'undefined') return;
  if (document.getElementById('askuni-widget-embed-root')) return;
  const container = document.createElement('div');
  container.id = 'askuni-widget-embed-root';
  document.body.appendChild(container);
  ReactDOM.createRoot(container).render(<WidgetContainer />);
})();