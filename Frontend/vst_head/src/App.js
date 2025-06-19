import React from "react";
import { BrowserRouter as Router, Routes, Route, useLocation, Outlet } from "react-router-dom";
import Login from "./pages/Login";
import Customer from "./pages/customer";
import Staff from "./pages/staff";
import EditReq from "./pages/editReq";
import UnavaReq from "./pages/unavaReq";
import CreateCard from "./pages/createcard";
import Service from "./pages/service";
import Sidebar from "./components/Sidebar";
import ShowCard from "./pages/showcard";
import Essentials from "./pages/essentials";
import NotFound from "./pages/NotFound";
import "./App.css";

const HeadLayout = () => {
  const location = useLocation();
  const showSidebar = !/^\/head\/?$/.test(location.pathname);

  return (
    <div className="app-container">
      {showSidebar && <Sidebar />}
      <div className="content">
        <Outlet />
      </div>
    </div>
  );
};

const App = () => {
  return (
    <Router>
      <Routes>
        {/* All /head... pages */}
        <Route path="/head" element={<HeadLayout />}>
          <Route index element={<Login />} />
          <Route path="customer" element={<Customer />} />
          <Route path="staff" element={<Staff />} />
          <Route path="editreq" element={<EditReq />} />
          <Route path="unavareq" element={<UnavaReq />} />
          <Route path="createcard" element={<CreateCard />} />
          <Route path="showcard" element={<ShowCard />} />
          <Route path="service" element={<Service />} />
          <Route path="essentials" element={<Essentials />} />
        </Route>

        {/* All OTHER ROUTES ➔ NotFound */}
        <Route path="*" element={<NotFound />} />
      </Routes>
    </Router>
  );
};

export default App;
