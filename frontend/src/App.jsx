import React, { useEffect, useState } from 'react';
import CollegeLandingPage from './components/CollegeLandingPage';
import WidgetContainer from './components/WidgetContainer';
import AdminDashboard from './pages/AdminDashboard';
import SysAdminPanel from './pages/SysAdminPanel';

export default function App() {
  const [route, setRoute] = useState(() => window.location.pathname || '/');

  useEffect(() => {
    const onPop = () => setRoute(window.location.pathname || '/');
    window.addEventListener('popstate', onPop);
    return () => window.removeEventListener('popstate', onPop);
  }, []);

  const navigate = (path) => {
    window.history.pushState({}, '', path);
    setRoute(path);
  };

  if (route === '/admin') {
    return <AdminDashboard onNavigate={navigate} />;
  }

  if (route === '/sysadmin') {
    return <SysAdminPanel onNavigate={navigate} />;
  }

  return (
    <>
      <CollegeLandingPage onNavigate={navigate} />
      <WidgetContainer />
    </>
  );
}